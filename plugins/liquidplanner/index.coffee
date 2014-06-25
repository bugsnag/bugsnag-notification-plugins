NotificationPlugin = require "../../notification-plugin"

class LiquidPlanner extends NotificationPlugin
  BASE_URL = "https://app.liquidplanner.com"

  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)

  description = (event) ->
    """
    #{event.trigger.message} in #{event.project.name}

    *#{event.error.exceptionClass}* in *#{event.error.context}*
    #{event.error.message if event.error.message}

    Stacktrace:
    #{stacktraceLines(event.error.stacktrace).join("\n")}
    """

  @receiveEvent: (config, event, callback) ->
    # Build the task info.
    payload =
      task:
        name: "#{event.error.exceptionClass} in #{event.error.context} from Bugsnag"
        description: description(event)
        link:
          title: "Bugsnag entry"
          url: "#{event.error.url}"

    config.host = BASE_URL unless config.host

    # Send the request
    @request
      .post(config.host + "/api/workspaces/" + config.space_id + "/tasks")
      .timeout(4000)
      .auth(config.username, config.password)
      .set('Accept', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback({status: res.error.status, message: res.error.message, body: res.body}) if res.error

        callback null,
          id: res.body.id
          url: config.host + "/space/"+config.space_id+"/projects/show/" + res.body.id

module.exports = LiquidPlanner
