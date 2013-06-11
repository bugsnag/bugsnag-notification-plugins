NotificationPlugin = require "../../notification-plugin"

class Webhook extends NotificationPlugin
  @receiveEvent: (config, event) ->
    payload = JSON.stringify(event).replace(/\．/g,".")

    # Send the request to the url
    @request
      .post(config.url)
      .type('json')
      .send(payload)
      .end();

module.exports = Webhook