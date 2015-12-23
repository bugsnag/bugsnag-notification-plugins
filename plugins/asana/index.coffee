async = require "async"

NotificationPlugin = require "../../notification-plugin"

class Asana extends NotificationPlugin
  BASE_URL = "https://app.asana.com/api/1.0"

  asanaDesc = (event) ->
      """
      #{event.error.exceptionClass} in #{event.error.context}
      #{event.error.message if event.error.message}

      #{event.error.url}

      #{event.error.occurrences} occurences
      #{event.error.usersAffected} users affected

      ===
      COMPLETE THIS TASK IN BUGSNAG. IT WILL BE AUTOMATICALLY CLOSED IN ASANA.
      """

  @issueUrl: (issueId) ->
    "#{BASE_URL}/tasks/#{issueId}"

  @storiesUrl: (issueId) ->
    "#{@issueUrl(issueId)}/stories"

  @asanaRequest: (req, config) ->
    req
      .timeout(10000)
      .type("form")
      .set("Authorization","Bearer " + config.personalAccessToken)

  @ensureIssueOpen: (config, event, callback) ->
    @asanaRequest(@request.put(@issueUrl(event.error.createdIssue.id)), config)
      .send({"completed": false, "notes": asanaDesc(event)})
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
      # Build task payload
      taskPayload =
        name: "[#{event.error.usersAffected}] #{event.error.exceptionClass}"
        notes: asanaDesc(event)
        projects: [config.projectId]
      # Create the task
      @asanaRequest(@request.post("#{BASE_URL}/tasks?workspace=" + config.workspaceId), config)
        .send(taskPayload)
        .on("error", (err) -> callback(err))
        .end (res) ->
          return callback(res.error) if res.error

          callback null,
            id: res.body.data.id
            url: "https://app.asana.com/0/#{config.projectId}/#{res.body.data.id}"

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)

    if event?.error?.createdIssue?.id
      if event?.trigger?.type == "comment"
        @addCommentToIssue(config, event.error.createdIssue.id,
          event.user.name + ": " + event.comment.message)
      if event?.trigger?.type == "projectSpiking"
        @addCommentToIssue(config, event.error.createdIssue.id,
          event.trigger.message + " - " + event.trigger.rate + " exceptions per minute")
      @ensureIssueOpen(config, event, callback)
    else
      if event?.trigger?.type == "firstException"
        @openIssue(config, event, callback)

module.exports = Asana
