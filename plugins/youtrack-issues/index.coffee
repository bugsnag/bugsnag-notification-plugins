NotificationPlugin = require "../../notification-plugin.js"

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
          url: res.header.location

  @receiveEvent = (config, event, callback) ->
    @fetchToken config, (err, token) =>
      return callback err if err # Unable to authenticate
      @createTicket config, event, token, callback

  @render = Handlebars.compile(
    """
    == {{trigger.message}} in {{project.name}} ==

    '''{{error.exceptionClass}}''' in '''{{error.context}}'''
    {{#if error.message}}{{error.message}}{{/if}}

    [View on bugsnag.com|{{error.url}}]

    == Stacktrace ==

    {html}<pre>{{#each error.stacktrace}}{{#if inProject}}
    {{file}}:{{lineNumber}} - {{method}}{{/if}}{{/each}}</pre>{html}

    [View full stacktrace|{{error.url}}]
    """
  )

module.exports = YouTrack