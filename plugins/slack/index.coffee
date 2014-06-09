NotificationPlugin = require "../../notification-plugin.js"

class Slack extends NotificationPlugin
  @errorAttachment = (event) ->
    fallback: "Something happened",
    fields: [
      {
        title: "Error"
        value: (event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)
      },
      {
        title: "Location",
        value: event.error.stacktrace && @firstStacktraceLine(event.error.stacktrace)
      }
    ]

  @receiveEvent = (config, event, callback) ->
    # Build the notification title
    title = ["#{event.trigger.message} in #{event.error.releaseStage} from <#{event.project.url}|#{event.project.name}>"]
    title.push("in #{event.error.context}")
    title.push("<#{event.error.url}|(details)>")

    # Build the common payload
    payload = {
      username: "Bugsnag",
      text: title.join(" "),
      attachments: []
    }

    # Attach error information
    payload.attachments.push(@errorAttachment(event)) if event.error

    # Post to slack
    @request
      .post(config.url)
      .timeout(4000)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

module.exports = Slack
