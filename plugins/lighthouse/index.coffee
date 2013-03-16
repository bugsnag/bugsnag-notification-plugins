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

  @receiveEvent: (config, event, callback) ->
    # Build the ticket payload
    payload = 
      ticket:
        title: "#{event.error.exceptionClass} in #{event.error.context}"
        body: markdownBody(event)
        tag: config.tags

    # Send the request to the url
    @request
      .post("#{config.url}/projects/#{config.projectId}/tickets.json")
      .set("X-LighthouseToken", config.apiKey)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.ticket.number
          url: res.body.ticket.url

module.exports = Lighthouse