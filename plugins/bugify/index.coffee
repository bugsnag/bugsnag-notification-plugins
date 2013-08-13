NotificationPlugin = require "../../notification-plugin"

class Bugify extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)

  markdownBody = (event) ->
    """
    ## #{event.trigger.message} in #{event.project.name}

    **#{event.error.exceptionClass}** in **#{event.error.context}**
    #{event.error.message if event.error.message}

    [View on bugsnag.com](#{event.error.url})

    ## Stacktrace

        #{stacktraceLines(event.error.stacktrace).join("\n")}

    [View full stacktrace](#{event.error.url})
    """

  @receiveEvent: (config, event, callback) ->
    payload =
      subject: "#{event.error.exceptionClass} in #{event.error.context}"
      description: markdownBody(event)
      project: config.projectId

    @request
      .post("#{config.url}/api/issues.json")
      .auth(config.apiKey, "")
      .type("form")
      .set('Accept', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.issue_id
          url: "#{config.url}/issues/#{res.body.issue_id}"

module.exports = Bugify
