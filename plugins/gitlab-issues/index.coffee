NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin
  @baseUrl: (config) ->
    "#{config.gitlab_url}/api/v3/projects/"

  @issuesUrl: (config, id) ->
    @baseUrl(config) + id + '/issues'

  @findProjectId: (config, projects) ->
    project = projects.filter (p) ->
      p.name == encodeURIComponent(config.project_name)
    project[0].id

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"

    # Build the ticket
    payload =
      title: @title(event)
      description: @markdownBody(event)
      labels: (config?.labels || "bugsnag")

    @request.get(@baseUrl(config))
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
      .end (res) =>
        @request.post(@issuesUrl(config, @findProjectId(config, res.body)))
          .send(payload)
          .set("User-Agent", "Bugsnag")
          .set("PRIVATE-TOKEN", config.private_token)
          .on("error", callback)
          .end (res) ->
            return callback(res.error) if res.error
            callback null,
              id: res.body.id
              url: "#{config.gitlab_url}/#{config.project_name}/issues/#{res.body.id}"

module.exports = GitLabIssue
