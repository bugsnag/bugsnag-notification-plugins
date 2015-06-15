NotificationPlugin = require '../../notification-plugin'
Handlebars = require 'handlebars'
url = require 'url'

module.exports = class BugHerd extends NotificationPlugin

  # Resolve the bugs rest api endpoint
  tasksUrl = (config) ->
    "https://www.bugherd.com/api_v2/projects/#{config.projectId}/tasks.json"

  # Parses the user's input of tags for the task
  parseTags = (tags) -> tags?.split /, */

  # Build the request payload
  @requestPayload = (config, event) ->
    task:
      description: @textBody event
      priority: config.priority
      tag_names: parseTags config.tags
      status: config.status

  # Compose the really simple message body
  @textBody = Handlebars.compile(
    """
      {{#if error.message}}{{error.message}}{{/if}}
      ({{error.exceptionClass}} in {{error.context}})

      {{error.url}}

      Stacktrace:{{#eachSummaryFrame error.stacktrace}}
      {{file}}:{{lineNumber}} - {{method}}{{/eachSummaryFrame}}
    """
  )

  # Receive the configuration & event payload
  @receiveEvent = (config, event, callback) ->

    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)
    return if event?.trigger?.type == 'reopened'

    @request
      .post tasksUrl config
      .auth config.apiKey, 'x'
      .send @requestPayload config, event
      .on 'error', (err) ->
        callback err
      .end (res) ->
        return callback res.error if res.error

        callback null,
          id: res?.body?.task?.id
          url: res?.body?.task?.admin_link
