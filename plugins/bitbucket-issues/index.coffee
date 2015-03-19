NotificationPlugin = require "../../notification-plugin"
url = require "url"
qs = require 'qs'

class BitbucketIssue extends NotificationPlugin
  BASE_URL = "https://bitbucket.org"

  @issuesUrl: (config) ->
    "#{BASE_URL}/api/1.0/repositories/#{config.repo}/issues"

  @issueUrl: (config, issueId) ->
    @issuesUrl(config) + "/" + issueId

  @commentsUrl: (config, issueId) ->
    @issueUrl(config, issueId) + "/comments"

  @bitbucketRequest: (req, config) ->
    req
      .timeout(4000)
      .auth(config.username, config.password)
      .set('Accept', 'application/json')

  @ensureIssueOpen: (config, issueId, callback) ->
    @bitbucketRequest(@request.put(@issueUrl(config, issueId)), config)
      .send(qs.stringify({status: "new"}))
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

  @addCommentToIssue: (config, issueId, comment) ->
    @bitbucketRequest(@request.post(@commentsUrl(config, issueId)), config)
      .send(qs.stringify({content: comment}))
      .on("error", console.error)
      .end()

  @openIssue: (config, event, callback) ->
    query_object =
      "title": @title(event)
      "content": @markdownBody(event)
      "kind": config.kind
      "priority": config.priority

    # Send the request
    @bitbucketRequest(@request.post(@issuesUrl(config)), config)
      .send(qs.stringify(query_object))
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback({status: res.error.status, message: res.error.message, body: res.body}) if res.error

        callback null,
          id: res.body.local_id
          url: url.resolve(BASE_URL, "#{config.repo}/issue/#{res.body.local_id}")

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)

    if event?.trigger?.type == "reopened"
      if event?.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = BitbucketIssue
