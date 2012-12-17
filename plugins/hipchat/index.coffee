NotificationPlugin = require "../../notification-plugin"

class Hipchat extends NotificationPlugin
  HIPCHAT_API_ENDPOINT = "https://api.hipchat.com/v1/rooms/message"

  @receiveEvent: (config, event) ->

    if event.error
      # Build the message for error notifications
      error_string = (event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)
      
      message =  "<b>#{event.trigger.message} in #{event.error.releaseStage}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a> in <b>#{event.error.context}</b> (<a href=\"#{event.error.url}\">details</a>)"
      message += "<br>&nbsp;&nbsp;&nbsp;#{error_string}"
      message += "<br>&nbsp;&nbsp;&nbsp;<code>#{@firstStacktraceLine(event.error.stacktrace)}</code>" if event.error.stacktrace
    else    
      # Build the message for non-error events
      message =  "<b>#{event.trigger.message}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a>"

    # Build the request
    params = 
      from: "Bugsnag"
      message: message
      auth_token: config.authToken
      room_id: config.roomId
      notify: config.notify || false
      color: config.color || "yellow"

    # Send the request to hipchat
    @request
      .post(HIPCHAT_API_ENDPOINT)
      .send(params)
      .type("form")
      .end()

module.exports = Hipchat