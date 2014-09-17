NotificationPlugin = require "../../notification-plugin"
url = require "url"
qs = require 'qs'

class BitbucketIssue extends NotificationPlugin
  BASE_URL = "https://bitbucket.org"

  @openIssue: (config, event, callback) ->
    query_object =
      "title": @title(event)
      "content": @markdownBody(event)
      "kind": config.kind
      "priority": config.priority

    # Send the request
    @request
      .post(url.resolve(BASE_URL, "/api/1.0/repositories/#{config.username}/#{config.repo}/issues"))
      .timeout(4000)
      .auth(config.username, config.password)
      .set('Accept', 'application/json')
      .send(qs.stringify(query_object))
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback({status: res.error.status, message: res.error.message, body: res.body}) if res.error

        callback null,
          id: res.body.local_id
          url: url.resolve(BASE_URL, "#{config.repo}/issue/#{res.body.local_id}")

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "reopened"
      if event?.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = BitbucketIssue
