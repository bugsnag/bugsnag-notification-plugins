NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin
  @baseUrl: (config) ->
    "#{config.gitlab_url}/api/v3/projects/"

  @issuesUrl: (config, projectId) ->
    @baseUrl(config) + projectId + '/issues'

  @issueUrl: (config, projectId, issueId) ->
    @issuesUrl(config, projectId) + '/' + issueId

  @notesUrl: (config, projectId, issueId) ->
    @issueUrl(config, projectId, issueId) + '/notes'

  @findProjectId: (config, projects) ->
    project = {}
    project = projects.filter (p) ->
      p.name == encodeURIComponent(config.project_id.split("/").slice(-1)[0])
    project[0].id

  @gitlabRequest: (req, config) ->
    req.set("User-Agent", "Bugsnag").set("PRIVATE-TOKEN", config.private_token)

  @openIssue: (config, event, callback) ->
    # Build the ticket
    payload =
      title: @title(event)
      description: @markdownBody(event)
      labels: (config?.labels || "bugsnag")

    @gitlabRequest(@request.get(@baseUrl(config)), config)
      .end (res) =>
        projectId = @findProjectId(config, res.body)
        @gitlabRequest(@request.post(@issuesUrl(config, projectId)), config)
          .send(payload)
          .on("error", callback)
          .end (res) ->
            return callback(res.error) if res.error
            callback null,
              id: res.body.id
              projectId: projectId
              url: "#{config.gitlab_url}/#{config.project_id}/issues/#{res.body.id}"

  @ensureIssueOpen: (config, projectId, issueId, callback) ->
    @gitlabRequest(@request.put(@issueUrl(config, projectId, issueId)), config)
      .send({state_event: "reopen"})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @addCommentToIssue: (config, event, id, comment) ->
    @gitlabRequest(@request.post(@notesUrl(config, event, id)), config)
      .send({body: comment})
      .on("error", console.error)
      .end()

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "reopened"
      if event.error?.createdIssue?.id
        projectId = event.error.createdIssue.projectId
        issueId = event.error.createdIssue.id
        @ensureIssueOpen(config, projectId, issueId, callback)
        @addCommentToIssue(config, projectId, issueId, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = GitLabIssue
