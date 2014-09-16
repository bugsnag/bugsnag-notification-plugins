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
      p.name == encodeURIComponent(config.project_slug.split("/").slice(-1)[0])
    project[0].id

  @openIssue: (config, event, callback) ->
    # Build the ticket
    payload =
      title: @title(event)
      description: @markdownBody(event)
      labels: (config?.labels || "bugsnag")

    @request.get(@baseUrl(config))
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
      .end (res) =>
        projectId = @findProjectId(config, res.body)
        @request.post(@issuesUrl(config, projectId))
          .send(payload)
          .set("User-Agent", "Bugsnag")
          .set("PRIVATE-TOKEN", config.private_token)
          .on("error", callback)
          .end (res) ->
            return callback(res.error) if res.error
            callback null,
              id: res.body.id
              projectId: projectId
              url: "#{config.gitlab_url}/#{config.project_slug}/issues/#{res.body.id}"

  @ensureIssueOpen: (config, projectId, issueId, callback) ->
    @request.put(@issueUrl(config, projectId, issueId))
      .send({state_event: "reopen"})
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @addCommentToIssue: (config, event, id, comment) ->
    @request.post(@notesUrl(config, event, id))
      .send({body: comment})
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
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
