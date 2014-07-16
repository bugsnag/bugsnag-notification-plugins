async = require "async"

NotificationPlugin = require "../../notification-plugin"

class Assembla extends NotificationPlugin
  API_BASE_URL = "https://api.assembla.com/v1"
  WEB_BASE_URL = "https://www.assembla.com"

  stacktraceLines = (stacktrace) ->
    anyInProject = stacktrace.some (el) -> el.inProject
    if anyInProject
      ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)
    else
      ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace[0..4])

  renderBody = (event) ->
    """
    *#{event.error.exceptionClass}* in *#{event.error.context}*

    #{event.error.message if event.error.message}

    [[url:#{event.error.url}|View on bugsnag.com]]

    Stacktrace:
    <pre><code>
    #{stacktraceLines(event.error.stacktrace).join("\n")}
    </code></pre>

    [[url:#{event.error.url}|View full stacktrace]]
    """

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"

    getSpace = (cb) =>
      @request.get("#{API_BASE_URL}/spaces.json")
        .timeout(4000)
        .set("Content-type", "application/json")
        .set("X-Api-key", config.apiKey)
        .set("X-Api-secret", config.apiSecret)
        .end (res) =>
          return cb(null, space) for space in res.body when space.wiki_name is config.space
          cb(new Error("Workspace not found with name '#{config.space}'"))

    validateTags = (space, cb) =>
      if config.tags
        tagNames = config.tags.split(",")
        @request.get("#{API_BASE_URL}/spaces/#{space.id}/tags.json")
          .timeout(4000)
          .set("Content-type", "application/json")
          .set("X-Api-key", config.apiKey)
          .set("X-Api-secret", config.apiSecret)
          .end (res) =>
            # Validate that the space contains the target tags
            if tagNames.every((tagName) -> res.body?.some?((tag) -> tag.name is tagName))
              cb(null, space: space, tagNames: tagNames)
            else
              cb(new Error("Tags not found in space '#{config.tags}'. Valid tags: '#{tag.name for tag in res.body}'"))
      else
        cb(null, space: space, tagNames: [])


    async.waterfall [getSpace, validateTags], (err, results) =>
      return callback(err) if err?

      {space, tagNames} = results

      # Build the ticket payload
      payload =
        ticket:
          summary: @title(event)
          description: renderBody(event)
          tags: tagNames

      # Create the ticket
      @request
        .post("#{API_BASE_URL}/spaces/#{space.id}/tickets.json")
        .timeout(4000)
        .set("Content-type", "application/json")
        .set("X-Api-key", config.apiKey)
        .set("X-Api-secret", config.apiSecret)
        .send(payload)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          return callback(res.error) if res.error

          callback null,
            id: res.body.id
            url: "#{WEB_BASE_URL}/spaces/#{space.wiki_name}/tickets/#{res.body.number}"

module.exports = Assembla
