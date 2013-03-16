NotificationPlugin = require "../../notification-plugin"

class GithubIssue extends NotificationPlugin
  BASE_URL = "https://api.github.com"

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
    # Build the ticket
    payload = 
      title: "#{event.error.exceptionClass} in #{event.error.context}"
      body: markdownBody(event)

    # Send the request
    @request
      .post("#{BASE_URL}/repos/#{config.repo}/issues")
      .auth(config.username, config.password)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.id
          number: res.body.number
          url: res.body.html_url

module.exports = GithubIssue