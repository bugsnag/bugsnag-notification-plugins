NotificationPlugin = require "../../notification-plugin"
Handlebars = require 'handlebars'

class Flowdock extends NotificationPlugin
  BASE_URL = "https://api.flowdock.com/v1"

  @receiveEvent: (config, event, callback) ->

    subject = "#{event.trigger.message} in #{event.project.name}"

    link = if event.error
             event.error.url
           else
             event.project.url

    # Flowdock projects can only contain alphanumeric characters, "_" and " "
    project = event.project.name.replace(/[^\w_]+/g, ' ')

    payload =
      source: "Bugsnag"
      from_address: "notifications@bugsnag.com"
      from_name: "Bugsnag"
      format: "html"
      subject: subject
      project: project
      content: @render event
      link: link

    @request
      .post("#{BASE_URL}/messages/team_inbox/#{config.apiToken}")
      .send(payload)
      .set("User-Agent", "Bugsnag")
      .on "error", (err) ->
        callback err
      .end (res) ->
        callback(res.error)

  @render: Handlebars.compile '
    {{#if error}}
      <p>
        <a href="{{error.url}}">
          <strong>{{error.exceptionClass}} in {{error.context}}</strong>
        </a>
        <br/>
        {{error.message}}
      </p>
      {{#if releaseStage}}
        <p>Release stage: {{releaseStage}}</p>
      {{/if}}
      {{#if appVersion}}
        <p>App version: {{appVersion}}</p>
      {{/if}}

      <p><strong>Stacktrace summary</strong></p>
      <table>
      {{#each error.stacktrace}}
        <tr><td><tt>{{file}}:{{lineNumber}} - {{method}}</tt></td></tr>
      {{/each}}
      </table>
    {{else}}
      {{trigger.message}} in <a href="{{project.url}}">{{project.name}}</a>
    {{/if}}
    '

module.exports = Flowdock
