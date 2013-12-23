NotificationPlugin = require "../../notification-plugin"

class Bugify extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    payload =
      subject: @title(event)
      description: @markdownBody(event)
      project: config.projectId

    @request
      .post("#{config.url}/api/issues.json")
      .timeout(4000)
      .auth(config.apiKey, "")
      .type("form")
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.issue_id
          url: "#{config.url}/issues/#{res.body.issue_id}"

module.exports = Bugify
