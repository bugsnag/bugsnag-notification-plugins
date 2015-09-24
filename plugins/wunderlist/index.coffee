NotificationPlugin = require "../../notification-plugin"

class Wunderlist extends NotificationPlugin

  @webhookURLPrefix = "https://in.wunderlist.com/"

  @receiveEvent = (config, event, callback) ->

    if ~config.url.indexOf @webhookURLPrefix

      # Post to Wunderlist
      @request
        .post(config.url)
        .timeout(4000)
        .send(event)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          callback(res.error)

    else
      callback "Invalid config.url, must start with " + @webhookURLPrefix

module.exports = Wunderlist
