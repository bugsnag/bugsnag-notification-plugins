url = require 'url'

NotificationPlugin = require '../../notification-plugin'
xmlRpc = require './xmlRpc'

class BugzillaRPC

  @setHost: (config) ->
    xmlRpc.host = url.resolve(config.host, config.project)

  @login: (request, config, callback) ->
    @setHost(config)
    xmlRpc.methodCall request, 'User.login', [
      login: config.login
      password: config.password
    ], callback

  @createBug: (request, config, token, event) ->
    @setHost(config)
    xmlRpc.methodCall request, 'Bug.create', [
      Bugzilla_token: token
      product: config.product
      component: config.component
      summary: NotificationPlugin.title(event)
      version: 'unspecified'
      description: NotificationPlugin.markdownTemplate(event)
      op_sys: config['op-sys']
      platform: config.platform
      priority: config.priority
      severity: config.severity
      assigned_to: config['assigned-to']
      status: config.status
    ]

module.exports = BugzillaRPC;
