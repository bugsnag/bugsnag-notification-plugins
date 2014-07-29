xml2js = require "xml2js"
require "sugar"

NotificationPlugin = require "../../notification-plugin"

class PivotalTracker extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"

    # Build the request
    params =
      "story[name]": "#{event.error.exceptionClass} in #{event.error.context}".truncate(5000)
      "story[story_type]": "bug"
      "story[labels]": (config?.labels || "bugsnag").trim()
      "story[description]":
        """
        *#{event.error.exceptionClass}* in *#{event.error.context}*
        #{event.error.message if event.error.message}
        #{event.error.url}

        *Stacktrace:*
        #{@basicStacktrace(event.error.stacktrace)}
        """.truncate(20000)

    # Send the request to the url
    @request
      .post("https://www.pivotaltracker.com/services/v3/projects/#{config.projectId}/stories")
      .timeout(4000)
      .set("X-TrackerToken", config.apiToken)
      .type("form")
      .send(params)
      .buffer(true)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        # Pivotal tracker api responds in XML :(
        parser = new xml2js.Parser(ignoreAttrs: true, explicitArray: false)
        parser.parseString res.text, (err, result) ->
          callback null,
            id: result.story.id
            url: result.story.url

module.exports = PivotalTracker
