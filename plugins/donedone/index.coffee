require "sugar"

NotificationPlugin = require "../../notification-plugin"
FormUrlencoded = require 'form-urlencoded'

class DoneDone extends NotificationPlugin
  @baseUrl: (config) ->
    "https://#{config.subdomain}.mydonedone.com/issuetracker/api/v2/projects/#{config.projectId}"

  @issuesUrl: (config) ->
    "#{@baseUrl(config)}/issues.json"

  @commentUrl: (config, issueId) ->
    "#{@baseUrl(config)}/issues/#{issueId}/comments.json"

  @issueWebUrl: (config, issueId) ->
    "https://#{config.subdomain}.mydonedone.com/issuetracker/projects/#{config.projectId}/issues/#{issueId}"

  @sendRequest: (req, config) ->
    req
      .auth(config.username, config.apitoken)

  @addCommentToIssue: (config, issueId, comment, callback) ->
    @sendRequest(@request.post(@commentUrl(config, issueId)), config)
      .send(FormUrlencoded.encode({"comment": comment}))
      .on "error", (err) ->
        callback(err)
      .end()

  @openIssue: (config, event, callback) ->
    # Build the request
    params =
      "title": "#{event.error.exceptionClass} in #{event.error.context}".truncate(5000)
      "priority_level_id": "1"
      "fixer_id": "#{config.defaultFixerId}"
      "tester_id": "#{config.defaultTesterId}"
      "tags": (config?.labels || "bugsnag").trim()
      "description":
        """
        *#{event.error.exceptionClass}* in *#{event.error.context}*
        #{event.error.message if event.error.message}
        #{event.error.url}

        *Stacktrace:*
        #{@basicStacktrace(event.error.stacktrace)}
        """.truncate(20000)

    # Send the request to the url
    req = @sendRequest(@request.post(@issuesUrl(config)), config)
      .send(FormUrlencoded.encode(params))
      .on "error", (err) ->
        callback(err)
      .end (res) =>
        return callback(res.error) if res.error
        callback null,
          id: res.body.order_number
          url: @issueWebUrl(config, res.body.order_number)

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "reopened"
      if event.error?.createdIssue?.id
        @addCommentToIssue(config, event.error.createdIssue.id, @markdownBody(event), callback)
    else
      @openIssue(config, event, callback)

module.exports = DoneDone
