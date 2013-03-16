xml2js = require "xml2js"

NotificationPlugin = require "../../notification-plugin"

class PivotalTracker extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)

  @receiveEvent: (config, event, callback) ->
    # Build the request
    params =
      "story[name]": "#{event.error.exceptionClass} in #{event.error.context}"
      "story[story_type]": "bug"
      "story[labels]": "bugsnag"
      "story[description]":      
        """
        *#{event.error.exceptionClass}* in *#{event.error.context}*
        #{event.error.message if event.error.message}
        #{event.error.url}

        *Stacktrace:*
        #{stacktraceLines(event.error.stacktrace).join("\n")}
        """

    # Send the request to the url
    @request
      .post("https://www.pivotaltracker.com/services/v3/projects/#{config.projectId}/stories")
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