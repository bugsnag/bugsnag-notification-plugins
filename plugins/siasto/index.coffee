async = require "async"

NotificationPlugin = require "../../notification-plugin"

class Siasto extends NotificationPlugin
  BASE_URL = "https://www.siasto.com/api/v2"

  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)

  @receiveEvent: (config, event) ->
    # Create the task
    @request
      .post("#{BASE_URL}/tasks")
      .auth(config.apiKey, "")
      .type("form")
      .send
        name: "TODO"
        description: "TODO"
        project_id: config.projectId
        tags: ["bugsnag"]
        assignee_ids: ["TODO"]
      .end (res) ->
        console.log "Status code: #{res.status}"
        console.log res.text || "No response from siasto!"

module.exports = Siasto