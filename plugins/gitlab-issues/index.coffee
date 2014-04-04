NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin
  @getProject: (config, cb) =>
    @request
      .get("#{config.gitlab_url}/api/v3/projects/search/#{config.project_id.replace('.', '_')}?per_page=10")
      .timeout(4000)
      .set("User-Agent", "Bugsnag")
      .set("PRIVATE-TOKEN", config.private_token)
      .on "error", (err) ->
        cb(err)
      .end (res) ->
        return cb(res.error) if res.error

        project = res.body?.find? (el) -> [el.name, el.name_with_namespace, el.path, el.path_with_namespace].indexOf config.projectName != -1

        cb null, project
    
  @receiveEvent: (config, event, callback) =>
    @getProject config, (err, project) =>
      return callback(err) if err

      # Build the ticket
      payload = 
        title: @title(event)
        description: @markdownBody(event)
        labels: "bugsnag"

      # Send the request
      @request
        .post("#{config.gitlab_url}/api/v3/projects/#{project.id}/issues")
        .set("User-Agent", "Bugsnag")
        .set("PRIVATE-TOKEN", config.private_token)
        .send(payload)
        .on("error", callback)
        .end (res) ->
          return callback(res.error) if res.error

          callback null,
            id: res.body.id
            url: "#{config.gitlab_url}/#{project.path_with_namespace || project.path}/issues/#{res.body.id}"

module.exports = GitLabIssue