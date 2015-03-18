NotificationPlugin = require "../../notification-plugin"

class Webhook extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->

    return if event?.trigger?.type == "linkExistingIssue"

    payload = JSON.stringify(event).replace(/\．/g,".")

    # Send the request to the url
    @request
      .post(config.url)
      .timeout(4000)
      .type('json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error
        callback()

module.exports = Webhook
