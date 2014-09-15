NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin
  @receiveEvent: (config, event, callback) =>
    return if event?.trigger?.type == "reopened"

    # Build the ticket
    payload =
      title: @title(event)
      description: @markdownBody(event)
      labels: (config?.labels || "bugsnag")

    baseUrl = "#{config.gitlab_url}/api/v3/projects/"

    @request.get(baseUrl)
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
      .end (res) =>
        projectId = 0
        res.body.map (project) ->
          if project.name == encodeURIComponent(config.project_name)
            projectId = project.id

        @request.post(baseUrl + projectId + '/issues')
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
