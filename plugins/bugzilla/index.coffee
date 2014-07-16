NotificationPlugin = require '../../notification-plugin'
bugzillaRPC = require './bugzillarpc'

class Bugzilla extends NotificationPlugin

  @receiveEvent: (config, event, callback) ->
    bugzillaRPC.createBug(config, event, callback)

module.exports = Bugzilla
