NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'
url = require "url"

class Jaconda extends NotificationPlugin

  @receiveEvent: (config, event, callback) ->

    return if event?.trigger?.type == "linkExistingIssue"

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

    else

      details =
        title: event.trigger.message

      # Non-error events
      message =  "<b>#{event.trigger.message}</b> from <a href=\"#{event.project.url}\">#{event.project.name}</a>"

    # Build the payload
    payload = 
      message:
        text: @render details
        sender_name: "Bugsnag"

    # Send the request
    @request
      .post(url.resolve(config.host, "/api/v2/rooms/#{config.roomId}/notify.json"))
      .timeout(4000)
      .auth("#{config.apiToken}", "X")
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback({status: res.error.status, message: res.error.message, body: res.body}) if res.error

        callback null,
          id: res.body.message.id

  @render: Handlebars.compile(
    '{{#if comment}}' +
      '<b>{{user.name}}</b> commented on <b>{{error_string}}</b> (<a href="{{error.url}}">details</a>)' +
      '<br/>&nbsp;&nbsp;&nbsp;"{{comment.message}}"' +
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

module.exports = Jaconda
