NotificationPlugin = require "../../notification-plugin"

class GithubIssue extends NotificationPlugin
  BASE_URL = "https://api.github.com"

  @issuesUrl: (config) -> "#{BASE_URL}/repos/#{config.repo}/issues"
  @issueUrl: (config, issueNumber) -> "#{@issuesUrl(config)}/#{issueNumber}"

  @githubRequest: (req, config) ->
    req.timeout(4000).set("User-Agent", "Bugsnag")

    if config.oauthToken
      req.set("Authorization", "token #{config.oauthToken}")
    else
      req.auth(config.username, config.password)

  @addCommentToIssue: (config, issueNumber, comment) ->
    @githubRequest(@request.post("#{@issueUrl(config, issueNumber)}/comments"), config)
      .send({body: comment})
      .on "error", console.error
      .end()

  @ensureIssueOpen: (config, issueNumber, callback) ->
    @githubRequest(@request.patch(@issueUrl(config, issueNumber)), config)
      .send({state: "open"})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @openIssue: (config, event, callback) ->
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
      labels: payloadLabels.split(/\s*,\s*/).compact(true)

    @githubRequest(@request.post(@issuesUrl(config)), config)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.id
          number: res.body.number
          url: res.body.html_url

  @receiveEvent: (config, event, callback) ->
    if event?.error?.createdIssue?.number
      @ensureIssueOpen(config, event.error.createdIssue.number, callback)
      @addCommentToIssue(config, event.error.createdIssue.number, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = GithubIssue
