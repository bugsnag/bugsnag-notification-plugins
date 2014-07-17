NotificationPlugin = require "../../notification-plugin"

class UserVoice extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"
    
    # Build the payload
    payload =
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
          #{@basicStacktrace(event.error.stacktrace)}
          """

    # Send the request
    url = if config.url.startsWith(/https?:\/\//) then config.url else "https://#{config.url}"
    @request
      .post("#{url}/api/v1/tickets.json")
      .timeout(4000)
      .send(payload)
      .type("form")
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.ticket.id
          number: res.body.ticket.ticket_number
          url: "#{url}/admin/tickets/#{res.body.ticket.ticket_number}"

module.exports = UserVoice
