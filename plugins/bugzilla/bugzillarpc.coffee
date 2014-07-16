url = require 'url'

NotificationPlugin = require '../../notification-plugin'
xmlRpc = require './xmlRpc'

class BugzillaRPC

  @createBug: (config, event, callback) ->
    xmlRpc.host = url.resolve(config.host, config.project)

    @login config, callback, (token) ->
      bug_params = [
        Bugzilla_token: token
        product: config.product
        component: config.component
        summary: NotificationPlugin.title(event)
        version: 'unspecified'
        description: NotificationPlugin.markdownTemplate(event)
        op_sys: 'All'
        platform: 'All'
        priority: config.priority
      ]
      xmlRpc.methodCall('Bug.create', bug_params, callback)

  @login: (config, callback, tokenCallback) ->
    login_params = [ login: config.login, password: config.password ]
    xmlRpc.methodCall('User.login', login_params, callback, tokenCallback)

module.exports = BugzillaRPC;
