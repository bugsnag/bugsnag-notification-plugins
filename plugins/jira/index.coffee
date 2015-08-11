NotificationPlugin = require "../../notification-plugin"
url = require "url"

class Jira extends NotificationPlugin
  jiraBody = (event) ->
    """
    h1. #{event.trigger.message} in #{event.project.name}

    *#{event.error.exceptionClass}* in *#{event.error.context}*
    #{event.error.message if event.error.message}

    [View on Bugsnag|#{event.error.url}]

    h1. Stacktrace

    {noformat}
    #{NotificationPlugin.basicStacktrace(event.error.stacktrace)}
    {noformat}

    [View full stacktrace|#{event.error.url}]
    """

  @baseUrl: (config) ->
    url.resolve(config.host, "rest/api/2")

  @issuesUrl: (config) ->
    @baseUrl(config) + "/issue"

  @issueUrl: (config, issueId) ->
    "#{@issuesUrl(config)}/#{issueId}"

  @getTransitionUrl: (config, issueId) ->
    @issueUrl(config, issueId) + "/transitions"

  @postTransitionUrl: (config, issueId) ->
    @issueUrl(config, issueId) + "/transitions?expand=transitions.fields"

  @commentUrl: (config, issueId) ->
    @issueUrl(config, issueId) + "/comment"

  @jiraRequest: (req, config) ->
    req
      .timeout(4000)
      .auth(config.username, config.password)
      .set('Accept', 'application/json')

  @ensureIssueOpen: (config, issueId, callback) ->
    @jiraRequest(@request.get(@getTransitionUrl(config, issueId)), config)
      .on "error", (err) ->
        callback(err)
      .end (res) =>
        callback(res.error) if res.error

        return unless res.body.transitions

        transition = res.body.transitions.filter((obj) -> obj.name == 'Reopen')[0]
        return unless transition

        payload = {
          "transition": { "id": transition.id }
        }

        @jiraRequest(@request.post(@postTransitionUrl(config, issueId)), config)
          .send(payload)
          .on "error", (err) ->
            callback(err)
          .end (res) ->
            callback(res.error) if res.error

  @addCommentToIssue: (config, issueId, comment, callback) ->
    @jiraRequest(@request.post(@commentUrl(config, issueId)), config)
      .send({body: comment})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error) if res.error

  @openIssue: (config, event, callback) ->
    # Build the ticket payload
    payload =
      fields:
        project:
          key: config.projectKey
        summary: "#{event.error.exceptionClass} in #{event.error.context}"
        description: jiraBody(event)
        issuetype:
          name: config.issueType

    # Add an optional component to the request
    if config.component
      payload.fields.components = [{name: config.component}]

    # Add an optional custom fields to the request
    if config.customFields
      Object.merge(payload.fields, JSON.parse(config.customFields))

    # https://example.com/jira becomes https://example.com/jira/
    config.host += "/" unless /\/$/.test(config.host)

    # Send the request
    @jiraRequest(@request.post(@issuesUrl(config)), config)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback({status: res.error.status, message: Object.values(res.body.errors).first(), body: res.body}) if res.error

        callback null,
          id: res.body.id
          key: res.body.key
          url: url.resolve(config.host, "browse/#{res.body.key}")

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)

    if event?.trigger?.type == "reopened"
      if event?.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, jiraBody(event), callback)
    else
      @openIssue(config, event, callback)

module.exports = Jira
