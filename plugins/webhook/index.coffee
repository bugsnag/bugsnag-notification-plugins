NotificationPlugin = require "../../notification-plugin"

class Webhook extends NotificationPlugin
  @receiveEvent: (config, event) ->
    # Send the request to the url
    @request
      .post(config.url)
      .send(event)
      .end();

module.exports = Webhook