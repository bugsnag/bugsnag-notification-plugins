NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class Gitter extends NotificationPlugin
  BASE_URL = "https://api.gitter.im/v1"

  @receiveEvent: (config, event, callback) ->

    if event.error
      details =
        title: "#{event.trigger.message} in #{event.error.releaseStage}"
        error_string: (event.error.exceptionClass + (if event.error.message then ": #{event.error.message}")).truncate(85)
        stack_trace_line: event.error.stacktrace && @firstStacktraceLine(event.error.stacktrace)
        project: event.project
        error: event.error
        rate: event.trigger.rate
    else
      details =
        title: event.trigger.message

    payload =
      text: @render(details)

    @request.get("#{BASE_URL}/rooms")
      .set('Authorization', "Bearer #{config.token}")
      .timeout(4000)
      .on "error", (err) ->
        callback(err)
      .end (res) =>
        callback(res.error) if res.error
        callback(res.body) unless Object.isArray(res.body)

        room = res.body.find (r) ->
          r['name'] == config.repo
        return unless room

        @request.post("#{BASE_URL}/rooms/#{room['id']}/chatMessages")
          .timeout(4000)
          .set('Authorization', "Bearer #{config.token}")
          .send(payload)
          .on "error", (err) ->
            console.log err
            callback(err)
          .end (res) ->
            return callback(res.error) if res.error
            callback(null)

  @render: Handlebars.compile(
    '**{{title}}** from [{{project.name}}]({{project.url}})' +
    '{{#if error}}' +
      ' in **{{error.context}}** ([details]({{error.url}}))' +
      '\n&nbsp;&nbsp;&nbsp;{{error_string}}' +
      '{{#if stack_trace_line}}\n&nbsp;&nbsp;&nbsp;`{{stack_trace_line}}`{{/if}}' +
    '{{/if}}'
  )

module.exports = Gitter
