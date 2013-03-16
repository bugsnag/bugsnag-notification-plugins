NotificationPlugin = require "../../notification-plugin"

class Jira extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)
      
  jiraBody = (event) ->
    """
    h1. #{event.trigger.message} in #{event.project.name}

    *#{event.error.exceptionClass}* in *#{event.error.context}*
    #{event.error.message if event.error.message}

    [View on bugsnag.com|#{event.error.url}]

    h1. Stacktrace

        #{stacktraceLines(event.error.stacktrace).join("\n")}

    [View full stacktrace|#{event.error.url}]
    """
  
  @receiveEvent: (config, event, callback) ->
    # Build the ticket payload
    payload =
      fields:
        project: 
          key: config.projectKey
        summary: "#{event.error.exceptionClass} in #{event.error.context}"
        description: jiraBody(event)
        issuetype:
          name: config.issueType

    # Send the request
    @request
      .post("#{config.host}/rest/api/2/issue")
      .auth(config.username, config.password)
      .set('Accept', 'application/json')
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          id: res.body.id
          key: res.body.key
          url: "#{config.host}/browse/#{res.body.key}"
        
module.exports = Jira