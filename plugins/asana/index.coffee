async = require "async"

NotificationPlugin = require "../../notification-plugin"

class Asana extends NotificationPlugin
  BASE_URL = "https://app.asana.com/api/1.0"

  stacktraceLines = (stacktrace) ->
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject)
  
  markdownBody = (event) ->
    """
    #{event.error.exceptionClass} in #{event.error.context}

    #{event.error.message if event.error.message}

    View on bugsnag.com:
    #{event.error.url}

    Stacktrace:
    #{stacktraceLines(event.error.stacktrace).join("\n")}
    """

  @receiveEvent: (config, event, callback) ->
    # Look up workspace id from project name
    getWorkspaceId = (cb) =>
      @request
        .get("#{BASE_URL}/workspaces")
        .auth(config.apiKey, "")
        .on("error", (err) -> cb(err))
        .end (res) =>
          return cb(res.error) if res.error

          workspace = res.body?.data?.find? (el) -> el.name == config.workspaceName
          if workspace
            cb null, workspace.id
          else
            cb new Error("Workspace not found with name '#{config.workspaceName}'")

    # Look up project id from project name
    getProjectId = (cb) =>
      @request
        .get("#{BASE_URL}/projects")
        .auth(config.apiKey, "")
        .on("error", (err) -> cb(err))
        .end (res) =>
          return cb(res.error) if res.error
          return cb(null, null) unless config.projectName

          project = res.body?.data?.find? (el) -> el.name == config.projectName
          if project
            cb null, project.id
          else
            cb new Error("Project not found with name '#{config.projectName}'")

    # Look up workspace and project ids
    async.parallel
      workspaceId: getWorkspaceId
      projectId: getProjectId
    , (err, results) =>
      return callback(err) if err?

      # Build task payload
      taskPayload =
        name: "#{event.error.exceptionClass} in #{event.error.context}"
        notes: markdownBody(event)
        workspace: results.workspaceId

      taskPayload.projects = [results.projectId] if results.projectId?

      # Create the task
      @request
        .post("#{BASE_URL}/tasks")
        .send(taskPayload)
        .type("form")
        .auth(config.apiKey, "")
        .on("error", (err) -> callback(err))
        .end (res) ->
          return callback(res.error) if res.error

          callback null,
            id: res.body.data.id
            url: "https://app.asana.com/0/#{results.workspaceId}/#{res.body.data.id}"


module.exports = Asana