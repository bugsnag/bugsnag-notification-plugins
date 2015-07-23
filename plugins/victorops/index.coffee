NotificationPlugin = require "../../notification-plugin"

class VictorOps extends NotificationPlugin

  @receiveEvent: (config, event, callback) ->

    if event.trigger.type == 'projectSpiking'
      payload =
        message_type: 'CRITICAL'
        entity_id: event.project.url
        monitoring_tool: "Bugsnag"
        state_message: "Spike of #{event.trigger.rate} exceptions/minute in #{event.project.name}"

    else
      payload =
        message_type: "CRITICAL"
        entity_id: event.error.url.split("?")[0]
        monitoring_tool: "Bugsnag"
        state_message: "#{event.error.exceptionClass} in #{event.error.context}"

    # Send the request
    @request
      .post("https://alert.victorops.com/integrations/generic/20131114/alert/#{config.apiKey}/#{config.routingKey}")
      .timeout(4000)
      .set('Content-Type', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error
        callback()

module.exports = VictorOps
