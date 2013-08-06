NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class Hipchat extends NotificationPlugin
  BASE_URL = "https://api.hipchat.com/v1"

  @receiveEvent: (config, event, callback) ->
    # Build the message
    if event.error

      details =
        title: "#{event.trigger.message} in #{event.error.releaseStage}"
        error_string: (event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)
        stack_trace_line: event.error.stacktrace && @firstStacktraceLine(event.error.stacktrace)
        project: event.project
        error: event.error

    else

      details =
        title: event.trigger.message

      # Non-error events
      message =  "<b>#{event.trigger.message}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a>"

    # Build the payload
    payload =
      from: "Bugsnag"
      message: @render details
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

  @render: Handlebars.compile(
    '<b>{{title}}</b> from <a href="{{project.url}}">{{project.name}}</a>' +
    '{{#if error}}' +
      ' in <b>{{error.context}}</b> (<a href="{{error.url}}">details</a>)' +
      '<br>&nbsp;&nbsp;&nbsp;{{error_string}}' +
      '{{#if stack_trace_line}}<br>&nbsp;&nbsp;&nbsp;{{stack_trace_line}}{{/if}}' +
    '{{/if}}'
  )


module.exports = Hipchat
