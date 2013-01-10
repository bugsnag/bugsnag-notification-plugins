NotificationPlugin = require "../../notification-plugin"

class Asana extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)
  
  markdownBody = (event) ->
    """#{event.error.exceptionClass} in #{event.error.context}

#{event.error.message if event.error.message}
  
View on bugsnag.com:
#{event.error.url}
  
Stacktrace:
#{stacktraceLines(event.error.stacktrace).join("\n")}"""
    
  @receiveEvent: (config, event) ->
    # Look up the workspace id
    @request
      .get("https://app.asana.com/api/1.0/workspaces")
      .auth(config.apiKey, "")
      .end (res) =>
        workspace = res.body?.data?.find? (el) -> el.name == config.workspaceName

        # Build the request
        params = 
          name: "#{event.error.exceptionClass} in #{event.error.context}"
          notes: markdownBody(event)
          workspace: workspace.id
        
        # Send the request to the url
        @request
          .post("https://app.asana.com/api/1.0/tasks")
          .send(params)
          .type("form")
          .auth(config.apiKey, "")
          .end (res) ->
            console.log res.body.data.id

module.exports = Asana
# 
# 
# curl -u <api_key>: https://app.asana.com/api/1.0/tasks \
#     -d "assignee=1235" \
#     -d "followers[0]=5678" \
#     -d "name=Hello, world%21" \
#     -d "notes=How are you today%3F" \
#     -d "workspace=14916"