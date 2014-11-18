NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class Hipchat extends NotificationPlugin
  API_BASE_URL = "https://api.hipchat.com/"

  getApiUrl = (config, path) ->
    if config.host?
      host = if /\/$/.test(config.host) then config.host else config.host + "/"
    else
      host = API_BASE_URL

    "#{host}#{path}?auth_token=#{config.authToken}"

  @receiveEvent: (config, event, callback) ->
    # Build the message
    if event.error
      details =
        title: "#{event.trigger.message} in #{event.error.releaseStage}"
        error_string: (event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)
        stack_trace_line: event.error.stacktrace && @firstStacktraceLine(event.error.stacktrace)
        project: event.project
        error: event.error
        spiking: event.trigger.type == 'projectSpiking'
        rate: event.trigger.rate
        comment: event.comment
        user: event.user

      if details.comment?.message
        details.comment.message = details.comment.message.truncate(80)

    else
      details =
        title: event.trigger.message

    # Build the payload
    payload =
      from: "Bugsnag"
      message: @render details
      notify: ["1", "true", true].indexOf(config.notify) != -1
      color: config.color || "yellow"

    # Send the request
    if config.authToken.length == 40
      @request
        .post(getApiUrl(config, "v2/room/#{config.roomId}/notification"))
        .set("Content-Type", "application/json")
        .timeout(4000)
        .send(payload)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          callback(res.error)

    else
      payload.room_id = config.roomId
      @request
        .post(getApiUrl(config, "v1/rooms/message"))
        .type("form")
        .timeout(4000)
        .send(payload)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          callback(res.error)


  @render: Handlebars.compile(
    '{{#if comment}}' +
      '<b>{{user.name}}</b> commented on <b>{{error_string}}</b> (<a href="{{error.url}}">details</a>)' +
      '<br>&nbsp;&nbsp;&nbsp;"{{comment.message}}"' +
    '{{else}}' +
      '{{#if spiking}}' +
        'Spike of <b>{{rate}}</b> exceptions/minute in <a href="{{project.url}}">{{project.name}}</a><br/>' +
        'Most recent error: {{error_string}} (<a href="{{error.url}}">details</a>)' +
      '{{else}}' +
        '<b>{{title}}</b> from <a href="{{project.url}}">{{project.name}}</a>' +
        '{{#if error}}' +
          ' in <b>{{error.context}}</b> (<a href="{{error.url}}">details</a>)' +
          '<br>&nbsp;&nbsp;&nbsp;{{error_string}}' +
          '{{#if stack_trace_line}}<br>&nbsp;&nbsp;&nbsp;<code>{{stack_trace_line}}</code>{{/if}}' +
        '{{/if}}' +
      '{{/if}}' +
    '{{/if}}'
  )

module.exports = Hipchat
