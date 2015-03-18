NotificationPlugin = require "../../notification-plugin"

Handlebars = require "handlebars"
url = require "url"
cookie = require "cookie"

class YouTrack extends NotificationPlugin

  resolveUrl = (config, path) ->
    url.resolve config.url, path

  handleCookies = (res) ->
    res.headers['set-cookie'].map((item) ->
      parsed = cookie.parse item
      key = Object.keys(parsed)[0]
      cookie.serialize key, parsed[key],
        path: parsed.Path
    ).join '; '

  loginUrl = (config) -> resolveUrl config, 'rest/user/login'
  ticketUrl = (config) -> resolveUrl config, 'rest/issue'

  @fetchToken = (config, callback) ->
    @request
      .post loginUrl(config)
      .type 'form'
      .send
        login: config.username
        password: config.password
      .on 'error', (err) ->
        callback err
      .end (res) ->
        return callback res.error if res.error
        return callback "401: Unable to login - please check your credentials" unless res.headers['set-cookie']
        callback null, handleCookies res

  @createTicket = (config, event, token, callback) ->
    @request
      .put ticketUrl config
      .type 'form' # This isn't documented
      .set 'Cookie', token
      .query
        project: config.project
        summary: @title event
        description: @render event
      .on 'error', (err) ->
        callback err
      .end (res) ->
        return callback res.error if res.error
        callback null,
          url: res.header.location.replace("/rest/", "/")

  @receiveEvent = (config, event, callback) ->
    return if event?.trigger?.type == "linkExistingIssue"
    @fetchToken config, (err, token) =>
      return callback err if err # Unable to authenticate
      @createTicket config, event, token, callback

  @render = Handlebars.compile(
    """
    == {{trigger.message}} in {{project.name}} ==

    '''{{error.exceptionClass}}''' in '''{{error.context}}'''
    {{#if error.message}}{{error.message}}{{/if}}

    [View on Bugsnag|{{error.url}}]

    == Stacktrace ==

    {html}<pre>{{#eachSummaryFrame error.stacktrace}}
    {{file}}:{{lineNumber}} - {{method}}{{/eachSummaryFrame}}</pre>{html}

    [View full stacktrace|{{error.url}}]
    """
  )

module.exports = YouTrack
