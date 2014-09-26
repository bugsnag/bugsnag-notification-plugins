NotificationPlugin = require '../../notification-plugin'
Handlebars = require 'handlebars'
url = require 'url'

class Hall extends NotificationPlugin

  # End API access endpoint
  API_URL = 'https://hall.com/api/1/'

  # The image that displays for Bugsnag messages
  BUGSNAG_AVATAR = 'https://bugsnag.com/favicon96.png'

  # Gets the url to the message integration
  @chatUrl: (config) ->
    url.resolve API_URL, "services/generic/#{config.apiToken}"

  # Gets the body of the chat message
  @messageBody: Handlebars.compile(
    '{{#if error.message}}' +
      '&nbsp;&nbsp;&nbsp;{{error.exceptionClass}}: {{error.message}} (<a href="{{error.url}}">details</a>)' +
      '{{#if stack_trace_line}}<br>&nbsp;&nbsp;&nbsp;<code>{{stack_trace_line}}</code>{{/if}}' +
    '{{else}}' +
      '<b>{{trigger.message}}</b> from <a href="{{project.url}}">{{project.name}}</a>' +
    '{{/if}}'
  )

  @messageTitle: Handlebars.compile(
    '{{trigger.message}} in {{error.releaseStage}} from {{project.name}}' +
    '{{#if error}}' +
      ' in {{error.context}}' +
    '{{/if}}'
  )

  @spikingTitle: Handlebars.compile(
    'Spike of {{trigger.rate}} exceptions/minute from {{project.name}}'
  )

  @spikingMessage: Handlebars.compile(
    'Most recent error: {{error.exceptionClass}}: {{error.message}} (<a href="{{error.url}}">details</a>)'
  )

  @commentMessage: Handlebars.compile(
    '{{user.name}} commented on {{error.exceptionClass}}: {{error.message}} (<a href="{{error.url}}">details</a>)' +
    '<br/>&nbsp;&nbsp;&nbsp;"{{comment.message}}"'
  )

  # Build the request body
  @messagePayload = (config, event) ->
    if event.trigger.type == 'projectSpiking'
      title: @spikingTitle event
      message: @spikingMessage
        error: event.error
        trigger: event.trigger
        project: event.project
      picture: BUGSNAG_AVATAR

    else if event.trigger.type == 'comment'
      title: @messageTitle event
      message: @commentMessage
        user: event.user
        comment:
          message: event.comment.message.truncate(80)
        error: event.error
        trigger: event.trigger
        project: event.project
      picture: BUGSNAG_AVATAR

    else
      title: @messageTitle event
      message: @messageBody
        error: event.error
        stack_trace_line: event.error.stacktrace && @firstStacktraceLine(event.error.stacktrace)
        trigger: event.trigger
        project: event.project
      picture: BUGSNAG_AVATAR

  # Fire the event
  @receiveEvent = (config, event, callback) ->
    @request
      .post @chatUrl config
      .type 'json' # Content-Type: application/json
      .send @messagePayload config, event
      .on 'error', (err) ->
        callback err
      .end (res) ->
        callback res.error

module.exports = Hall
