NotificationPlugin = require "../../notification-plugin"

class Codebase extends NotificationPlugin
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

  @receiveEvent: (config, event) ->
    # Build the request
    body = 
      """
      <ticket>
        <summary>#{event.error.exceptionClass} in #{event.error.context}</summary>
        <ticket-type>bug</ticket-type>
        <description>#{markdownBody(event)}</description>
      </ticket>
      """

    # Send the request to the url
    @request
      .post("http://api3.codebasehq.com/#{config.project}/tickets")
      .set("Accept", "application/xml")
      .type("application/xml")
      .auth("#{config.account}/#{config.username}", config.apiKey)
      .send(body)
      .buffer(true)
      .end((res) ->
        console.log "Status code: #{res.status}"
        console.log res.text || "No response from Codebase!"
      );

module.exports = Codebase