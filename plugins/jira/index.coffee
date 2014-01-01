NotificationPlugin = require "../../notification-plugin"
url = require "url"

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

    # Add an optional component to the request
    if config.component?
      payload.fields.components = [{name: config.component}]

    # Send the request
    @request
      .post(url.resolve(config.host, "/rest/api/2/issue"))
      .timeout(4000)
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
          url: url.resolve(config.host, "/browse/#{res.body.key}")
        
module.exports = Jira