NotificationPlugin = require '../../notification-plugin'
Handlebars = require 'handlebars'
{parseString} = require 'xml2js'

module.exports = class FogBugz extends NotificationPlugin

  @apiUrl = (config, cmd) ->
    "#{config.url}/api.asp?cmd=#{cmd}"

  @caseUrl = (config, id) ->
    "#{config.url}/f/cases/#{id}"

  @logonUser = (config, callback) ->
    return callback null, config.token if config.token?

    @request
      .post @apiUrl config, 'logon'
      .query
        email: config.email
        password: config.password
      .on 'error', (err) ->
        callback err
      .end (res) ->
        return callback res.error if res.error

        parseString res.text, (err, obj) ->
          token = obj?.response?.token?[0]
          console.log token

          return callback 'Invalid response' if err or not token
          callback null, token

  @createCase = (config, event, token, callback) ->
    @request
    .post @apiUrl config, 'new'
      .query
        sTags: config.tags
        sTitle: @title event
        sProject: config.project
        sArea: config.area
        ixPriority: config.priorityId
        sEvent: @renderBody event
        token: token
    .on 'error', (err) ->
      callback err
    .end (res) ->
      return callback res.error if res.error

      parseString res.text, (err, obj) ->
        id = obj?.response?.case?[0].$?.ixBug

        return callback 'Invalid response' if err or not id
        callback null, id

  @logoffUser = (config, token, callback) ->
    return callback null if config.token

    @request
      .post @apiUrl config, 'logoff'
      .query
        token: token
      .on 'error', (err) ->
        callback err
      .end (res) ->
        return callback res.error if res.error
        callback null, res

  @receiveEvent = (config, event, callback) ->
    return if event?.trigger?.type == 'reopened'

    # 1 - Authenticate the user (if necessary)
    @logonUser config, (logonErr, token) =>
      return callback logonErr if logonErr

      # 3 - Create the issue
      @createCase config, event, token, (createErr, id) =>
        # If there was an error, and it's safe to quit at this point (ie.
        # the configuration provided a token - which does not need logging off
        # first... then...
        return callback createErr if createErr and config.token?

        # 3 - Destroy the token (if necessary)
        @logoffUser config, token, (logoutErr) =>
          return callback logoutErr if logoutErr or createErr

          # 4 - Callback with the case data
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
