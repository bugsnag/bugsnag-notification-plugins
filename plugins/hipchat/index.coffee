NotificationPlugin = require "../../notification-plugin"

class Hipchat extends NotificationPlugin
  BASE_URL = "https://api.hipchat.com/v1"

  @receiveEvent: (config, event, callback) ->
    # Build the message
    if event.error
      # Error events
      error_string = (event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)
      
      message =  "<b>#{event.trigger.message} in #{event.error.releaseStage}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a> in <b>#{event.error.context}</b> (<a href=\"#{event.error.url}\">details</a>)"
      message += "<br>&nbsp;&nbsp;&nbsp;#{error_string}"
      message += "<br>&nbsp;&nbsp;&nbsp;<code>#{@firstStacktraceLine(event.error.stacktrace)}</code>" if event.error.stacktrace
    else    
      # Non-error events
      message =  "<b>#{event.trigger.message}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a>"

    # Build the payload
    payload = 
      from: "Bugsnag"
      message: message
      auth_token: config.authToken
      room_id: config.roomId
      notify: config.notify || false
      color: config.color || "yellow"

    # Send the request
    @request
      .post("#{BASE_URL}/rooms/message")
      .send(payload)
      .type("form")
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

module.exports = Hipchat