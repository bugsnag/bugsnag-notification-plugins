NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin
  DEFAULT_URL = "https://gitlab.com"

  @baseUrl: (config) ->
    "#{config.gitlab_url || DEFAULT_URL}/api/v3/projects"

  @issuesUrl: (config) ->
    "#{@baseUrl(config)}/#{encodeURIComponent(config.project_id)}/issues"

  @issueUrl: (config, issueId) ->
    @issuesUrl(config) + "/" + issueId

  @notesUrl: (config, issueId) ->
    @issueUrl(config, issueId) + "/notes"

  @gitlabRequest: (req, config) ->
    req.set("User-Agent", "Bugsnag").set("PRIVATE-TOKEN", config.private_token)

  @openIssue: (config, event, callback) ->
    # Build the ticket
    payload =
      title: @title(event)
      description: @markdownBody(event)
      labels: (config?.labels || "bugsnag")

    @gitlabRequest(@request.post(@issuesUrl(config)), config)
      .send(payload)
      .on("error", callback)
      .end (res) ->
        return callback(res.error) if res.error
        callback null,
          id: res.body.id
          url: "#{config.gitlab_url || DEFAULT_URL}/#{config.project_id}/issues/#{res.body.id}"

  @ensureIssueOpen: (config, issueId, callback) ->
    @gitlabRequest(@request.put(@issueUrl(config, issueId)), config)
      .send({state_event: "reopen"})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @addCommentToIssue: (config, issueId, comment) ->
    @gitlabRequest(@request.post(@notesUrl(config, issueId)), config)
      .send({body: comment})
      .on("error", console.error)
      .end()

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "linkExistingIssue"

    if event?.trigger?.type == "reopened"
      if event.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = GitLabIssue
