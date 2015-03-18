NotificationPlugin = require "../../notification-plugin"

class Campfire extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->

    if event.trigger.type == 'projectSpiking'
      message = "Spike of #{event.trigger.rate} exceptions/minute from #{event.project.name}."

      message += " Most recent error:"
      message += " #{event.error.exceptionClass}" if event.error.exceptionClass
      message += " #{event.error.message}" if event.error.message
      message += ". (#{event.project.url})"

    else if event.trigger.type == 'comment'
      message = "#{event.user.name} commented on "
      message += " #{event.error.exceptionClass}" if event.error.exceptionClass
      message += " #{event.error.message}" if event.error.message
      message += "\"#{event.comment.message.truncate(80)}\""
      message += ". (#{event.error.url})"

    else
      # Build the message
      message = "#{event.trigger.message} in #{event.error.releaseStage} from #{event.project.name}!"
      if event.error
        message += " #{event.error.exceptionClass}" if event.error.exceptionClass
        message += ": #{event.error.message}" if event.error.message
        message += " (#{event.error.url})"
      else
        message += " (#{event.project.url})"

    # Send the request to campfire
    @request
      .post("https://#{config.domain}.campfirenow.com/room/#{config.roomId}/speak.json")
      .timeout(4000)
      .auth(config.authToken, "X")
      .redirects(0)
      .send
        message:
          body: message
          type: "TextMessage"
      .on "error", (err) ->
        callback err
      .end (res) ->
        return callback(new Error("Bad response code: #{res.status}")) unless 200 <= res.status < 300

        callback null,
          id: res.body.message.id

module.exports = Campfire
