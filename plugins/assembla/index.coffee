async = require "async"

NotificationPlugin = require "../../notification-plugin"

class Assembla extends NotificationPlugin
  API_BASE_URL = "https://api.assembla.com/v1"
  WEB_BASE_URL = "https://www.assembla.com"

  renderBody = (event) ->
    """
    *#{event.error.exceptionClass}* in *#{event.error.context}*

    #{event.error.message if event.error.message}

    [[url:#{event.error.url}|View on Bugsnag]]

    Stacktrace:
    <pre><code>
    #{NotificationPlugin.basicStacktrace(event.error.stacktrace)}
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

    async.waterfall [getSpace], (err, space) =>
      return callback(err) if err?

      tagNames = config.tags?.split(",")

      # Build the ticket payload
      payload =
        ticket:
          summary: @title(event)
          description: renderBody(event)
          tags: tagNames

      if config.customFields
        payload.ticket.custom_fields = JSON.parse(config.customFields)

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
