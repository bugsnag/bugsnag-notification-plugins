NotificationPlugin = require "../../notification-plugin"

class Kore extends NotificationPlugin
    @receiveEvent = (config, event, callback) ->

        @request
            .post(config.url)
            .set('Content-Type', 'application/json')
            .send(event)
            .end()

module.exports = Kore
