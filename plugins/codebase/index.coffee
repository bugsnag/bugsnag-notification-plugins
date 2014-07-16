NotificationPlugin = require "../../notification-plugin"

class Codebase extends NotificationPlugin
  BASE_URL = "http://api3.codebasehq.com"

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"
    
    # Build the ticket payload
    payload =
      ticket:
        summary: @title(event)
        description: @markdownBody(event)
        ticket_type: "bug"

    # Send the request to codebase
    @request
      .post("#{BASE_URL}/#{config.project}/tickets")
      .timeout(4000)
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
