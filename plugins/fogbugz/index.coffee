NotificationPlugin = require '../../notification-plugin'
Handlebars = require 'handlebars'
{parseString} = require 'xml2js'

module.exports = class FogBugz extends NotificationPlugin

  @apiUrl = (config, cmd) ->
    "#{config.url}/api.asp?cmd=#{cmd}"

  @caseUrl = (config, id) ->
    "#{config.url}/f/cases/#{id}"

  @createCase = (config, event, callback) ->
    @request
    .post @apiUrl config, 'new'
      .query
        sTags: config.tags
        sTitle: @title event
        sProject: config.project
        sArea: config.area
        ixPriority: config.priorityId
        sEvent: @renderBody event
        token: config.token
    .on 'error', (err) ->
      callback err
    .end (res) ->
      return callback res.error if res.error

      parseString res.text, (err, obj) ->
        id = obj?.response?.case?[0].$?.ixBug

        return callback 'Invalid response' if err or not id
        callback null, id

  @receiveEvent = (config, event, callback) ->
    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)
    return if event?.trigger?.type == 'reopened'

    # 1 - Create the issue
    @createCase config, event, (err, id) =>
      return callback err if err

      # 2 - Callback with the case data
      callback null,
        id: id,
        url: @caseUrl config, id

  # Fogbugz can do HTML, but it's unclear how (http://help.fogcreek.com/8202/xml-api)
  @renderBody = Handlebars.compile(
    """
    {{trigger.message}} in {{project.name}}

    {{error.exceptionClass}} in {{error.context}}
    {{#if error.message}}{{error.message}}{{/if}}

    {{error.url}}

    Stacktrace
    <code>
    {{#eachSummaryFrame error.stacktrace}}
    {{file}}:{{lineNumber}} - {{method}}{{/eachSummaryFrame}}
    </code>
    """
  )
