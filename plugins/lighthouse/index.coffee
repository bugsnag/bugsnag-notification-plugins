NotificationPlugin = require "../../notification-plugin"

class Lighthouse extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    # Build the ticket payload
    payload = 
      ticket:
        title: @title(event)
        body: @markdownBody(event)
        tag: config.tags

    # Send the request to the url
    @request
      .post("#{config.url}/projects/#{config.projectId}/tickets.json")
      .timeout(4000)
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