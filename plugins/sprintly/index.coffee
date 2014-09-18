NotificationPlugin = require "../../notification-plugin"
qs = require 'qs'

class Sprintly extends NotificationPlugin
  BASE_URL = "https://sprint.ly/api/products"

  @issuesUrl: (config) ->
    "#{BASE_URL}/#{config.projectId}/items.json"

  @issueUrl: (config, issueId) ->
    "#{BASE_URL}/#{config.projectId}/items/#{issueId}.json"

  @commentsUrl: (config, issueId) ->
    "#{BASE_URL}/#{config.projectId}/items/#{issueId}/comments.json"

  @sprintlyRequest: (req, config) ->
    req.auth(config.sprintlyEmail, config.apiKey)

  @ensureIssueOpen: (config, issueId, callback) ->
    @sprintlyRequest(@request.get(@issueUrl(config, issueId)), config)
      .on "error", (err) ->
        callback(err)
      .end (res) =>
        status = res.body.status
        if status
          if status == "completed" || status == "accepted"
            status = "someday"
          @sprintlyRequest(@request.post(@issueUrl(config, issueId)), config)
            .send(qs.stringify({status: status}))
            .on "error", (err) ->
              callback(err)
            .end (res) ->
              callback(res.error)

  @addCommentToIssue: (config, issueId, comment) ->
    @sprintlyRequest(@request.post(@commentsUrl(config, issueId)), config)
      .send(qs.stringify({body: comment, type: "commit"}))
      .on("error", console.error)
      .end()

  @openIssue: (config, event, callback) ->
    # Build the Sprint.ly API request
    # API documentation: https://sprintly.uservoice.com/knowledgebase/articles/98412-items
    description =
    """
    *#{event.error.exceptionClass}* in *#{event.error.context}*
    #{event.error.message if event.error.message}
    #{event.error.url}
    """

    query_object =
      "type": "defect"
      "title": "#{event.error.exceptionClass} in #{event.error.context}"
      "tags": "bugsnag"
      "description": description
      "status": config.sprintlyStatus

    @sprintlyRequest(@request.post(@issuesUrl(config)), config)
      .send(qs.stringify(query_object))
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        callback null,
          number: res.body.number
          url: res.body.short_url

  @receiveEvent: (config, event, callback) ->
    # if event?.trigger?.type == "reopened"
    #   if event?.error?.createdIssue?.number
        @ensureIssueOpen(config, 14, callback)
    #     @addCommentToIssue(config, event.error.createdIssue.number, @markdownBody(event))
    # else
    #   @openIssue(config, event, callback)

module.exports = Sprintly
