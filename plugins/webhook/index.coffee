NotificationPlugin = require "../../notification-plugin"

class Webhook extends NotificationPlugin
  @receiveEvent: (config, event) ->
    # Send the request to the url
    @httpPostJson config.url, event

module.exports = Webhook