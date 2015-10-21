NotificationPlugin = require "../../notification-plugin"

class OpsGenie extends NotificationPlugin
  opsGenieDetails = (event) ->
    details =
      message : event.trigger.message
      project : event.project.name
      class : event.error.exceptionClass
      url : event.error.url
      stackTrace : event.error.stacktrace
    details

  @receiveEvent: (config, event, callback) ->

    if event.trigger.type == 'projectSpiking'
      payload =
        service_key: config.serviceKey
        event_type: 'trigger'
        incident_key: event.project.url
        description: "Spike of #{event.trigger.rate} exceptions/minute in #{event.project.name}"
        details: opsGenieDetails(event)

    else
      payload =
        service_key: config.serviceKey
        event_type: 'trigger'
        # Use error url without unique event key to allow opsgenie to de-dupe
        incident_key: event.error.url.split('?')[0]
        description: "#{event.error.exceptionClass} in #{event.error.context}"
        details: opsGenieDetails(event)

    # Send the request
    @request
      .post('http://api.opsgenie.com/v1/json/pagerduty')
      .timeout(4000)
      .set('Content-Type', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error
        callback()

module.exports = OpsGenie
