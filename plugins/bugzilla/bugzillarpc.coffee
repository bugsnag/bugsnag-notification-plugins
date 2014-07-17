Handlebars = require 'handlebars'
fs = require 'fs'

NotificationPlugin = require '../../notification-plugin'
XmlRpc = require './xmlrpc'

class BugzillaRPC

  @createBug: (config, event, callback) ->
    xmlRpc = new XmlRpc(config.host)

    @login xmlRpc, config, callback, (token) =>
      bug_params = [
        Bugzilla_token: token
        product: config.product
        component: config.component
        summary: NotificationPlugin.title(event)
        version: 'unspecified'
        description: @render(event)
        op_sys: 'All'
        platform: 'All'
        priority: config.priority
      ]
      xmlRpc.methodCall('Bug.create', bug_params, callback)

  @login: (xmlRpc, config, callback, tokenCallback) ->
    login_params = [ login: config.login, password: config.password ]
    xmlRpc.methodCall('User.login', login_params, callback, tokenCallback)

  @render: Handlebars.compile(fs.readFileSync(__dirname + '/template.hbs', 'utf8'))

module.exports = BugzillaRPC;
