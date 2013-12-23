NotificationPlugin = require "../../notification-plugin.js"

class SlackPlugin extends NotificationPlugin
  @receiveEvent = (config, event, callback) ->
    payload = [@title(event)]
    payload = payload.concat event.error.message if event.error.message
    payload = payload.concat "<#{event.error.url}>"

    payload = JSON.stringify({ text: payload.join("\n"), username: "Bugsnag" })

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

module.exports = SlackPlugin
