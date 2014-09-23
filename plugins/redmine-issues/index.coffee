NotificationPlugin = require "../../notification-plugin"

Handlebars = require "handlebars"
url = require "url"

class Redmine extends NotificationPlugin

  # The issue creation api location
  @issuesUrl: (config) ->
    url.resolve config.host, "/issues.json?key=#{config.apiKey}"

  # The issue priority registry api location
  @priorityUrl: (config) ->
    url.resolve config.host, "/enumerations/issue_priorities.json"

  # The issue JSON body (creation payload)
  @payloadJson: (config, event, priorityId) ->
    issue:
      project_id: config.project
      subject: @title(event)
      description: @render(event)
      priority_id: priorityId

  # Fetch the priority id by it's pretty name
  @fetchPriorityId: (config, priorityName, callback) ->
    @request
      .get @priorityUrl config
      .end (res) ->
        for priority in res.body.issue_priorities
          if priority.name.toLowerCase() is priorityName.toLowerCase()
            callback null, priority.id
            return
        callback Error "Priority not found with name '#{priorityName}'"

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
    handleRequest = (priorityId) =>
      @request
        .post @issuesUrl(config)
        .type 'json' # Redmine JSON body
        .send @payloadJson config, event, priorityId
        .on 'error', handleError
        .end handleCallback

    # Fetch the priority id, and then handle the request
    @fetchPriorityId config, config.priority, (err, priorityId) ->
      return callback err if err
      handleRequest priorityId

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
