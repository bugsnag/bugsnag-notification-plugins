NotificationPlugin = require "../../notification-plugin"

class GithubIssue extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)
    
  @receiveEvent: (config, event) ->
    # Build the request
    params = 
      title: "#{event.error.exceptionClass} in #{event.error.context}"
      body:
        """
        ## #{event.trigger.message} in #{event.project.name}

        **#{event.error.exceptionClass}** in **#{event.error.context}**
        #{event.error.message if event.error.message}

        [View on bugsnag.com](#{event.error.url})

        ## Stacktrace

            #{stacktraceLines(event.error.stacktrace).join("\n")}

        [View full stacktrace](#{event.error.url})
        """

    # Send the request to the url
    @request
      .post("https://api.github.com/repos/#{config.repo}/issues")
      .send(params)
      .auth(config.username, config.password)
      .end();

module.exports = GithubIssue