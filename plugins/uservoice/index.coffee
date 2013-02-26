NotificationPlugin = require "../../notification-plugin"

class UserVoice extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)

  @receiveEvent: (config, event) ->
    # Build the request
    params = 
      name: "Bugsnag"
      client: config.apiKey
      email: "bugsnag@bugsnag.com"
      ticket:
        subject: "#{event.error.exceptionClass} in #{event.error.context}"
        message:
          """
          #{event.error.exceptionClass} in #{event.error.context}
          #{event.error.message if event.error.message}
          #{event.error.url}

          Stacktrace:
          #{stacktraceLines(event.error.stacktrace).join("\n")}
          """

    # Send the request to hipchat
    uservoiceUrl = if config.url.startsWith(/https?:\/\//) then config.url else "https://#{config.url}"
    
    @request
      .post("#{uservoiceUrl}/api/v1/tickets.json")
      .send(params)
      .type("form")
      .buffer(true)
      .end((res) ->
        console.log "Status code: #{res.status}"
        console.log res.text || "No response from UserVoice!"
      );

module.exports = UserVoice