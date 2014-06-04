NotificationPlugin = require "../../notification-plugin"

class PagerDuty extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)      

  pagerDutyDescription = (event) ->
    """
    #{event.trigger.message}</b> in #{event.project.name}

    #{event.error.exceptionClass} in #{event.error.context}
    #{event.error.message if event.error.message}

    View on bugsnag.com: #{event.error.url}

    #{stacktraceLines(event.error.stacktrace).join("\n")}

    View full stacktrace: #{event.error.url}

    """

  @receiveEvent: (config, event, callback) ->
    payload =
      service_key: config.serviceKey
      event_type: 'trigger'
      incident_key: event.error.url
      description: pagerDutyDescription(event)

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
