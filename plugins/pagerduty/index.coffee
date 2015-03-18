NotificationPlugin = require "../../notification-plugin"

class PagerDuty extends NotificationPlugin
  pagerDutyDetails = (event) ->
    details =
      message : event.trigger.message
      project : event.project.name
      class : event.error.exceptionClass
      url : event.error.url
      stackTrace : event.error.stacktrace
    details

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "linkExistingIssue"

    if event.trigger.type == 'projectSpiking'
      payload =
        service_key: config.serviceKey
        event_type: 'trigger'
        incident_key: event.project.url
        description: "Spike of #{event.trigger.rate} exceptions/minute in #{event.project.name}"
        details: pagerDutyDetails(event)

    else
      payload =
        service_key: config.serviceKey
        event_type: 'trigger'
        # Use error url without unique event key to allow pagerduty to de-dupe
        incident_key: event.error.url.split('?')[0]
        description: "#{event.error.exceptionClass} in #{event.error.context}"
        details: pagerDutyDetails(event)

    # Send the request
    @request
      .post('https://events.pagerduty.com/generic/2010-04-15/create_event.json')
      .timeout(4000)
      .set('Content-Type', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error
        callback()

module.exports = PagerDuty
