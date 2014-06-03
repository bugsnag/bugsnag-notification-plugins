NotificationPlugin = require "../../notification-plugin"

class GithubIssue extends NotificationPlugin
  BASE_URL = "https://api.github.com"

  @receiveEvent: (config, event, callback) ->

    # Create labels variable
    payloadLabels = (config?.labels || "bugsnag")
    # Check App Version Labeling
    payloadLabels += ","+event.error.appVersion if config.labelAppVersion  and event.error.appVersion?
    # Check Release Stage Labiling
    payloadLabels += ","+event.error.releaseStage if config.labelReleaseStage and event.error.releaseStage?

    # Build the ticket
    payload =
      title: @title(event)
      body: @markdownBody(event)
      # Regex removes surrounding whitespace around commas while retaining inner whitespace
      # and then creates an array of the strings
      labels: payloadLabels.trim().split(/\s*,\s*/).compact(true)

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