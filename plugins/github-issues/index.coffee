NotificationPlugin = require "../../notification-plugin"

class GithubIssue extends NotificationPlugin
  BASE_URL = "https://api.github.com"

  @receiveEvent: (config, event, callback) ->
    # Build the ticket
    payload =
      title: @title(event)
      body: @markdownBody(event)
      # Regex removes surrounding whitespace around commas while retaining inner whitespace
      # and then creates an array of the strings
      labels: (config?.labels || "bugsnag").trim().split(/\s*,\s*/).compact(true)

    # Start building the request
    req = @request
      .post("#{BASE_URL}/repos/#{config.repo}/issues")
      .timeout(4000)
      .set("User-Agent", "Bugsnag")

    # Authenticate the request
    if config.oauthToken
      req.set("Authorization", "token #{config.oauthToken}")
    else
      req.auth(config.username, config.password)

    # Send the request
    req
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