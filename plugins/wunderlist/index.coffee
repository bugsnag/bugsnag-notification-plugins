NotificationPlugin = require "../../notification-plugin"

class Wunderlist extends NotificationPlugin

  @receiveEvent = (config, event, callback) ->

    if ~config.url.indexOf "https://in.wunderlist.com/"

      # Post to Wunderlist
      @request
        .post(config.url)
        .timeout(4000)
        .send(event)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          callback(res.error)

module.exports = Wunderlist
