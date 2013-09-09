NotificationPlugin = require "../../notification-plugin"

class GithubIssue extends NotificationPlugin
  BASE_URL = "https://api.github.com"
  
  @receiveEvent: (config, event, callback) ->
    # Build the ticket
    payload = 
      title: @title(event)
      body: @markdownBody(event)
      labels: (config?.labels || "bugsnag").split(",").compact(true)

    # Send the request
    @request
      .post("#{BASE_URL}/repos/#{config.repo}/issues")
      .auth(config.username, config.password)
      .set("User-Agent", "Bugsnag")
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.id
          number: res.body.number
          url: res.body.html_url

module.exports = GithubIssue