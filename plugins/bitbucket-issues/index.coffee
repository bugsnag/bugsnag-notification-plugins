NotificationPlugin = require "../../notification-plugin"
url = require "url"
qs = require 'qs'

class BitbucketIssue extends NotificationPlugin
  BASE_URL = "https://bitbucket.org"
  @receiveEvent: (config, event, callback) ->

    query_object =
      "title": @title(event)
      "content": @markdownBody(event)
      "kind": config.kind
      "priority": config.priority

    # Send the request
    @request
      .post(url.resolve(BASE_URL, "/api/1.0/repositories/#{config.repo}/issues"))
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
          url: url.resolve(BASE_URL, "#{res.body.resource_uri}")

module.exports = BitbucketIssue