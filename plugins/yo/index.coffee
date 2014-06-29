NotificationPlugin = require "../../notification-plugin"
url = require "url"
BASE_URL = "http://api.justyo.co"

class Yo extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->

    # Send the request
    @request
      .post(url.resolve(BASE_URL, "/yoall/"))
      .timeout(4000)
      .set('Accept', 'application/json')
      .send({api_token: config.api_token})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.body.error) if res.body.error

        callback null,
          result: res.body.result

module.exports = Yo