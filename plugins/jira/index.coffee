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
  
  @receiveEvent: (config, event) ->
    if event.error
      params =
        fields:
          project: 
            key: config.projectKey
          summary: "#{event.error.exceptionClass} in #{event.error.context}"
          description: jiraBody(event)
          issuetype:
            name: config.issueType

      url = config.host + "/rest/api/2/issue"

      # Send the request to jira
      @request
        .post(url)
        .auth(config.username, config.password)
        .set('Content-Type', 'application/json')
        .set('Accept', 'application/json')
        .send(params)
        .buffer(true)
        .end((res) ->
          console.log "Status code: #{res.status}"
          console.log res.text || "No response from JIRA!"
        );
        

module.exports = Jira
