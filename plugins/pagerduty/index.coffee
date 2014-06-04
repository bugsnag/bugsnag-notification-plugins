NotificationPlugin = require "../../notification-plugin"

class PagerDuty extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)      
    
  pagerDutyDetails = (event) ->
    details = 
      message : event.trigger.message
      project : event.project.name
      class : event.error.exceptionClass
      url : event.error.url
      stackTrace : event.error.stacktrace
      metaData : event.error.metaData    
    details

  @receiveEvent: (config, event, callback) ->
    payload =
      service_key: config.serviceKey
      event_type: 'trigger'
      incident_key: event.error.url
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
