NotificationPlugin = require "../../notification-plugin"

class Campfire extends NotificationPlugin
  @receiveEvent: (config, event) ->
    # Build the message
    if event.error
      message = "#{event.error.exceptionClass}" + (if event.error.message then ": #{event.error.message}" else "") + " (#{event.error.url})"
    else
      message =  "#{event.trigger.name} in #{event.project.name} (#{event.project.url})" + ( if event.error then " in #{event.error.context} (#{event.error.url})" else "")

    # Build the request
    payload = 
      message:
        body: message
        type: "TextMessage"

    # Send the request to campfire
    @httpPostJson "https://#{config.authToken}:X@#{config.domain}.campfirenow.com/room/#{config.roomId}/speak.xml", payload

module.exports = Campfire