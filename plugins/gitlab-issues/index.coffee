NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin
  @receiveEvent: (config, event, callback) =>
    return if event?.trigger?.type == "reopened"

    # Build the ticket
    payload =
      title: @title(event)
      description: @markdownBody(event)
      labels: (config?.labels || "bugsnag")

    # Send the request
    @request
      .post("#{config.gitlab_url}/api/v3/projects/#{encodeURIComponent(config.project_id)}/issues")
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
      .send(payload)
      .on("error", callback)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.id
          url: "#{config.gitlab_url}/#{config.project_id}/issues/#{res.body.id}"

module.exports = GitLabIssue
