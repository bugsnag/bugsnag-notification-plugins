NotificationPlugin = require '../../notification-plugin'

url = require "url"
xmlrpc = require "xmlrpc"

class Bugzilla extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"

    # Build the ticket payload
    payload =
      product: config.product
      component: config.component
      summary: NotificationPlugin.title(event)
      version: 'unspecified'
      description: @textBody(event)
      op_sys: 'All'
      platform: 'All'
      priority: config.priority

    # https://example.com/bugzilla becomes https://example.com/bugzilla/
    config.host += "/" unless /\/$/.test(config.host)

    # Login and send the request
    client = xmlrpc.createClient(url: url.resolve(config.host, "xmlrpc.cgi"), cookies: true)
    client.methodCall "User.login", [login: config.login, password: config.password], (err, response) ->
      return callback({status: 401, code: err.faultCode, message: err.faultString}) if err

      client.methodCall "Bug.create", [payload], (err, response) ->
        return callback({status: 400, code: err.faultCode, message: err.faultString}) if err

        callback null,
          id: response.id,
          url: url.resolve(config.host, "show_bug.cgi?id=#{response.id}")

module.exports = Bugzilla
