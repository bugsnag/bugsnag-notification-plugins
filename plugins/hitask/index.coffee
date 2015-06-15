NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class HiTask extends NotificationPlugin
  API_BASE_URL = "https://hitask.com/api/v3/simple/item"

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

      # Build the payload
      payload =
        title: details.error_string
        note: @render details
        project: details.project.name
        api_key: config.api_key

      # Send the request
      @request
        .post(API_BASE_URL)
        .timeout(4000)
        .type('form')
        .send(payload)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          callback(res.error)


  @render: Handlebars.compile(
    '{{#if comment}}' +
      '*{{user.name}}* commented on *{{error_string}}* {{error.url}}' +
      '\n   "{{comment.message}}"' +
    '{{else}}' +
      '{{#if spiking}}' +
        'Spike of *{{rate}}* exceptions/minute in {{project.name}} {{project.url}}\n' +
        'Most recent error: {{error_string}} {{error.url}}' +
      '{{else}}' +
        '*{{title}}* from {{project.name}} {{project.url}}' +
        '{{#if error}}' +
          ' in *{{error.context}}* {{error.url}}' +
          '\n   {{error_string}}' +
          '{{#if stack_trace_line}}\n\n> {{stack_trace_line}}{{/if}}' +
        '{{/if}}' +
      '{{/if}}' +
    '{{/if}}'
  )

module.exports = HiTask
