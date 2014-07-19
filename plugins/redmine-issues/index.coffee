NotificationPlugin = require "../../notification-plugin.js"

Handlebars = require "handlebars"
url = require "url"

class Redmine extends NotificationPlugin

  # Map the visually appealing priority, with it's id
  priorityMap =
    low: 1
    normal: 2
    high: 3
    urgent: 4
    immediate: 5

  # The issue creation api location
  @issuesUrl: (config) ->
    url.resolve(config.host, "/issues.json?key=#{config.apiKey}")

  # The issue JSON body (creation payload)
  @payloadJson: (config, event) ->
    issue:
      project_id: config.project
      subject: @title(event)
      description: @render(event)
      priority_id: priorityMap[config.priority]

  @receiveEvent = (config, event, callback) ->
    return if event?.trigger?.type == "reopened"

    # Handle unknown error
    handleError = (err) ->
      callback err

    # Handle a full api response
    handleCallback = (res) ->
      # TODO Redmine doesn't really like to tell us the error
      return callback(res.error) if res.error

      # Provide the url & id to the redmine issue
      callback null,
        id: res.body.issue.id
        url: url.resolve(config.host, "/issues/#{res.body.issue.id}")

    # Send out the request to the issues API
    @request
      .post @issuesUrl(config)
      .type 'json' # Redmine JSON body
      .send @payloadJson(config, event)
      .on 'error', handleError
      .end handleCallback

  # Redmine flavoured message information
  # http://www.redmine.org/help/en/wiki_syntax.html
  @render: Handlebars.compile(
    """
    h2. {{trigger.message}} in {{project.name}}

    **{{error.exceptionClass}}** in **{{error.context}}**
    {{#if error.message}}{{error.message}}{{/if}}

    "View on bugsnag.com":{{error.url}}

    h2. Stacktrace

    <pre>{{#eachSummaryFrame error.stacktrace}}
    {{file}}:{{lineNumber}} - {{method}}{{/eachSummaryFrame}}</pre>

    "View full stacktrace":{{error.url}}
    """
  )

module.exports = Redmine
