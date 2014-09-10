NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class HipchatV2 extends NotificationPlugin
  BASE_URL = "https://api.hipchat.com/v2"

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
      message = "<b>#{event.trigger.message}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a>"

    # Build the payload
    payload =
      from: "Bugsnag"
      message: @render details
      notify: config.notify || false
      color: config.color || "yellow"

    # Send the request
    @request
      .post("#{BASE_URL}/room/#{config.roomId}/notification?auth_token=#{config.authToken}")
      .timeout(4000)
      .set("Content-Type", "application/json")
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @render: Handlebars.compile(
    '<b>{{title}}</b> from <a href="{{project.url}}">{{project.name}}</a>' +
    '{{#if error}}' +
      ' in <b>{{error.context}}</b> (<a href="{{error.url}}">details</a>)' +
      '<br>&nbsp;&nbsp;&nbsp;{{error_string}}' +
      '{{#if stack_trace_line}}<br>&nbsp;&nbsp;&nbsp;<code>{{stack_trace_line}}</code>{{/if}}' +
    '{{/if}}'
  )

module.exports = HipchatV2
