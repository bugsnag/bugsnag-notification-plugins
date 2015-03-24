NotificationPlugin = require "../../notification-plugin"

class Slack extends NotificationPlugin
  @errorAttachment = (event) ->
    attachment =
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
    switch event.error.severity
      when "error"
        attachment.color = "#E45F58"
      when "warning"
        attachment.color = "#FD9149"
      when "info"
        attachment.color = "#20A6DF"

    attachment

  @commentAttachment = (event) ->
    {
      color: "good"
      fallback: "Somebody commented"
      author_name: event.user.name
      text: event.comment.message
    }

  @receiveEvent = (config, event, callback) ->

    # Build the notification title
    projectName = event.project.name.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

    if event.trigger.type == 'comment'

      title = ["Comment on #{(event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)}"]
      title.push("<#{event.error.url}|(details)>")
    else if event.trigger.type == 'projectSpiking'
      title = ["Spike of #{event.trigger.rate} exceptions/minute from <#{event.project.url}|#{projectName}>"]

    else
      title = ["#{event.trigger.message} in #{event.error.releaseStage} from <#{event.project.url}|#{projectName}>"]
      title.push("in #{event.error.context}")
      title.push("<#{event.error.url}|(details)>")

    # Build the common payload
    payload = {
      username: "Bugsnag",
      text: title.join(" "),
      attachments: []
    }

    # Attach error information
    if event.comment
      payload.attachments.push(@commentAttachment(event))
    else if event.error
      payload.attachments.push(@errorAttachment(event))

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
