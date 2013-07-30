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
    
  @receiveEvent: (config, event, callback) ->
    # Build the ticket
    payload = 
      title: "#{event.error.exceptionClass} in #{event.error.context}"
      labels: "bugsnag"
      description: markdownBody(event)
      private_token: config.private_token

    # Send the request
    @request
      .post("#{config.gitlab_url}/api/v3/projects/#{config.project_id}/issues")
      .set("User-Agent", "Bugsnag")
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.id
          url: "#{config.gitlab_url}/#{config.project_id}/issues/#{res.body.id}"

module.exports = GitLabIssue