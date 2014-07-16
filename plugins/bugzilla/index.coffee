url = require 'url'

NotificationPlugin = require '../../notification-plugin'
bugzillaRPC = require './bugzillarpc'

class Bugzilla extends NotificationPlugin

  @receiveEvent: (config, event, callback) ->
    bugzillaRPC.login @request, config, (token) =>
      bugzillaRPC.createBug @request, config, token, event

module.exports = Bugzilla
