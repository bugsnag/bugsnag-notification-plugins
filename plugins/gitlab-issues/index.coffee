NotificationPlugin = require "../../notification-plugin"

class GitLabIssue extends NotificationPlugin

  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)

  markdownBody = (event) ->
    """
    ## #{event.trigger.message} in #{event.project.name}

    **#{event.error.exceptionClass}** in **#{event.error.context}**
    #{event.error.message if event.error.message}

    [View on bugsnag.com](#{event.error.url})

    ## Stacktrace

        #{stacktraceLines(event.error.stacktrace).join("\n")}

    [View full stacktrace](#{event.error.url})
    """

  @getProject: (config, cb) =>
    @request
      .get("#{config.gitlab_url}/api/v3/projects/?per_page=100")
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
        title: "#{event.error.exceptionClass} in #{event.error.context}"
        labels: "bugsnag"
        description: markdownBody(event)

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