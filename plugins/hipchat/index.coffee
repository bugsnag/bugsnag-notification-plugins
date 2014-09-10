NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class Hipchat extends NotificationPlugin
  API_BASE_URL = "https://api.hipchat.com/"

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

    if config.authToken.length == 40
      apiVer = 2
    else
      apiVer = 1

    # Build the payload
    payload =
      from: "Bugsnag"
      message: @render details
      notify: config.notify || false
      color: config.color || "yellow"

    url = "#{API_BASE_URL}v#{apiVer}"

    if apiVer == 2
      url += "/room/#{config.roomId}/notification?auth_token=#{config.authToken}"
    else
      payload.auth_token = config.authToken
      payload.room_id = config.roomId
      url += "/rooms/message"

    # Send the request
    resp = @request.post(url).timeout(4000).send(payload)

    if apiVer == 2
      resp.set("Content-Type", "application/json")
    else
      resp.type("form")

    resp.on "error", (err) ->
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

module.exports = Hipchat
