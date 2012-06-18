NotificationPlugin = require "../../notification-plugin"

class Hipchat extends NotificationPlugin
  HIPCHAT_API_ENDPOINT = "https://api.hipchat.com/v1/rooms/message"

  @receiveEvent: (config, event) ->
    # Build the message
    message =  "<b>#{event.trigger.name}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a>" + ( if event.error then " in <b>#{event.error.context}</b> (<a href=\"#{event.error.url}\">details</a>)" else "")
    message += "<br>&nbsp;&nbsp;&nbsp;#{event.error.exceptionClass}" + (if event.error.message then ": #{event.error.message}" else "") if event.error
    message += "<br>&nbsp;&nbsp;&nbsp;<code>#{@firstStacktraceLine(event.error.stacktrace)}</code>" if event.error && event.error.stacktrace

    # Build the request
    params = 
      from: "Bugsnag"
      message: message
      auth_token: config.authToken
      room_id: config.roomId
      notify: config.notify || false
      color: config.color || "yellow"

    # Send the request to hipchat
    @httpPost HIPCHAT_API_ENDPOINT, params

module.exports = Hipchat