async = require "async"

NotificationPlugin = require "../../notification-plugin"

class Asana extends NotificationPlugin
  BASE_URL = "https://app.asana.com/api/1.0"

  @issueUrl: (issueId) ->
    "#{BASE_URL}/tasks/#{issueId}"

  @storiesUrl: (issueId) ->
    "#{@issueUrl(issueId)}/stories"

  @asanaRequest: (req, config) ->
    req
      .timeout(4000)
      .type("form")
      .auth(config.apiKey, "")

  @ensureIssueOpen: (config, issueId, callback) ->
    @asanaRequest(@request.put(@issueUrl(issueId)), config)
      .send({"completed": false})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @addCommentToIssue: (config, issueId, comment) ->
    @asanaRequest(@request.post(@storiesUrl(issueId)), config)
      .send({"text": comment})
      .on("error", console.error)
      .end()

  @openIssue: (config, event, callback) ->
    # Look up workspace id from project name
    getWorkspaceId = (cb) =>
      @request
        .get("#{BASE_URL}/workspaces")
        .timeout(4000)
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
      @asanaRequest(@request.get("#{BASE_URL}/projects"), config)
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
        notes: @textBody(event)
        workspace: results.workspaceId

      taskPayload.projects = [results.projectId] if results.projectId?

      # Create the task
      @asanaRequest(@request.post("#{BASE_URL}/tasks"), config)
        .send(taskPayload)
        .on("error", (err) -> callback(err))
        .end (res) ->
          return callback(res.error) if res.error

          callback null,
            id: res.body.data.id
            url: "https://app.asana.com/0/#{results.workspaceId}/#{res.body.data.id}"

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "linkExistingIssue"

    if event?.trigger?.type == "reopened"
      if event?.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, @textBody(event))
    else
      @openIssue(config, event, callback)

module.exports = Asana
