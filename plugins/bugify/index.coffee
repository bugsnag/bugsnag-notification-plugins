NotificationPlugin = require "../../notification-plugin"

class Bugify extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    payload = {}

    @request
      .post("#{config.url}")
      .auth(config.apiKey, "")
      .set('Accept', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        console.dir(res)

        callback null
        # callback null,
        #   id: res.body.id
        #   key: res.body.key
        #   url: "#{config.host}/browse/#{res.body.key}"

module.exports = Bugify