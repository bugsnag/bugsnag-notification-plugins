NotificationPlugin = require '../../notification-plugin'

url = require "url"
xmlrpc = require "xmlrpc"

class Bugzilla extends NotificationPlugin
  authedRequest = (config, method, payload, callback) ->
    host = if /\/$/.test(config.host) then config.host else config.host + "/"
    createClient = if config.host.startsWith("https://") then xmlrpc.createSecureClient else xmlrpc.createClient
    client = createClient(url: url.resolve(host, "xmlrpc.cgi"), cookies: true)
    client.methodCall "User.login", [login: config.login, password: config.password], (err, response) ->
      return callback({status: 401, code: err.faultCode, message: err.faultString}) if err

      if response.token
        payload.token = response.token

      client.methodCall method, [payload], (err, response) ->
        return callback({status: 400, code: err.faultCode, message: err.faultString}) if err

        callback null, response

  @addCommentToIssue: (config, event, callback) ->
    issueId = event?.error?.createdIssue?.url?.match(/\?id=(\d+)/)?[1]
    return callback(null, null) unless issueId

    payload =
      id: issueId
      comment: @textBody(event)

    # Create the new bug
    authedRequest config, "Bug.add_comment", payload, (err, response) ->
      return callback(err) if err

      callback null,
        id: issueId,
        url: url.resolve(config.host, "show_bug.cgi?id=#{issueId}")

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"

    # Normalize the url: https://example.com/bugzilla becomes https://example.com/bugzilla/
    config.host += "/" unless /\/$/.test(config.host)

    if event?.trigger?.type == "linkExistingIssue"
      @addCommentToIssue(config, event, callback)
    else
      # Build the ticket payload
      payload =
        product: config.product
        component: config.component
        summary: NotificationPlugin.title(event)
        version: config.version || 'unspecified'
        description: @textBody(event)
        op_sys: 'All'
        platform: 'All'
        priority: config.priority

      if config.customFields
        Object.merge(payload, JSON.parse(config.customFields))

      # Create the new bug
      authedRequest config, "Bug.create", payload, (err, response) ->
        return callback(err) if err

        callback null,
          id: response.id,
          url: url.resolve(config.host, "show_bug.cgi?id=#{response.id}")

module.exports = Bugzilla
