NotificationPlugin = require "../../notification-plugin"

class Lighthouse extends NotificationPlugin
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
    params = 
      ticket:
        title: "#{event.error.exceptionClass} in #{event.error.context}"
        body: markdownBody(event)
        tag: config.tags

    # Send the request to the url
    lighthouse_url = if config.url.startsWith("http://") then config.url else "http://#{config.url}"
    @request
      .post("#{lighthouse_url}/projects/#{config.projectId}/tickets.json")
      .set("X-LighthouseToken", config.apiKey)
      .send(params)
      .buffer(true)
      .end((res) ->
        console.log "Status code: #{res.status}"
        console.log res.text || "No response from Lighthouse!"
      );

module.exports = Lighthouse