NotificationPlugin = require "../../notification-plugin"

class Campfire extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    # Build the message
    message = "#{event.trigger.message} in #{event.project.name}!"
    if event.error
      message += " #{event.error.exceptionClass}" if event.error.exceptionClass
      message += ": #{event.error.message}" if event.error.message
      message += " (#{event.error.url})"
    else
      message += " (#{event.project.url})"

    # Send the request to campfire
    @request
      .post("https://#{config.domain}.campfirenow.com/room/#{config.roomId}/speak.json")
      .auth(config.authToken, "X")
      .send
        message:
          body: message
          type: "TextMessage"
      .on "error", (err) ->
        callback err
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.message.id

module.exports = Campfire