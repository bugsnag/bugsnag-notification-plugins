NotificationPlugin = require "../../notification-plugin"

class Codebase extends NotificationPlugin
  BASE_URL = "http://api3.codebasehq.com"

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
        summary: "#{event.error.exceptionClass} in #{event.error.context}"
        ticket_type: "bug"
        description: "#{markdownBody(event)}"

    # Send the request to codebase
    @request
      .post("#{BASE_URL}/#{config.project}/tickets")
      .set("Accept", "application/json")
      .auth("#{config.account}/#{config.username}", config.apiKey)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.ticket.ticket_id
          url: "https://#{config.account}.codebasehq.com/projects/#{config.project}/tickets/#{res.body.ticket.ticket_id}"

module.exports = Codebase