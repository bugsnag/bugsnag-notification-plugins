xml2js = require "xml2js"
require "sugar"

NotificationPlugin = require "../../notification-plugin"

class PivotalTracker extends NotificationPlugin
  BASE_URL = "https://www.pivotaltracker.com/services/v3/projects"

  @storiesUrl: (config) ->
    "#{BASE_URL}/#{config.projectId}/stories"

  @storyUrl: (config, storyId) ->
    @storiesUrl(config) + "/" + storyId

  @notesUrl: (config, storyId) ->
    @storyUrl(config, storyId) + "/notes"

  @ensureIssueOpen: (config, storyId, callback) ->
    params =
      "story[current_state]": "unstarted"

    @request
      .put(@storyUrl(config, storyId))
      .timeout(4000)
      .set("X-TrackerToken", config.apiToken)
      .type("form")
      .send(params)
      .buffer(true)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

  @addCommentToIssue: (config, storyId, comment) ->
    params =
      "note[text]": comment

    @request
      .post(@notesUrl(config, storyId))
      .timeout(4000)
      .set("X-TrackerToken", config.apiToken)
      .type("form")
      .send(params)
      .buffer(true)
      .on("error", console.error)
      .end()

  @openIssue: (config, event, callback) ->
    # Build the request
    params =
      "story[name]": "#{event.error.exceptionClass} in #{event.error.context}".truncate(5000)
      "story[story_type]": "bug"
      "story[labels]": (config?.labels || "bugsnag").trim()
      "story[description]":
        """
        *#{event.error.exceptionClass}* in *#{event.error.context}*
        #{event.error.message if event.error.message}
        #{event.error.url}

        *Stacktrace:*
        #{@basicStacktrace(event.error.stacktrace)}
        """.truncate(20000)

    # Send the request to the url
    @request
      .post(@storiesUrl(config))
      .timeout(4000)
      .set("X-TrackerToken", config.apiToken)
      .type("form")
      .send(params)
      .buffer(true)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

        # Pivotal tracker api responds in XML :(
        parser = new xml2js.Parser(ignoreAttrs: true, explicitArray: false)
        parser.parseString res.text, (err, result) ->
          callback null,
            id: result.story.id
            url: result.story.url

  @receiveEvent: (config, event, callback) ->
    if event?.trigger?.type == "reopened"
      if event.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = PivotalTracker
