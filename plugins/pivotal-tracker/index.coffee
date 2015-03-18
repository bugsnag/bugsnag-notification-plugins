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

  @pivotalRequest: (req, config) ->
    req
      .timeout(4000)
      .set("X-TrackerToken", config.apiToken)
      .type("form")
      .buffer(true)

  @ensureIssueOpen: (config, storyId, callback) ->
    @pivotalRequest(@request.put(@storyUrl(config, storyId)), config)
      .send({"story[current_state]": "unscheduled"})
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback(res.error) if res.error

  @addCommentToIssue: (config, storyId, comment) ->
    @pivotalRequest(@request.post(@notesUrl(config, storyId)), config)
      .send({"note[text]": comment})
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
    @pivotalRequest(@request.post(@storiesUrl(config)), config)
      .send(params)
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
    return if event?.trigger?.type == "linkExistingIssue"
    if event?.trigger?.type == "reopened"
      if event.error?.createdIssue?.id
        @ensureIssueOpen(config, event.error.createdIssue.id, callback)
        @addCommentToIssue(config, event.error.createdIssue.id, @markdownBody(event))
    else
      @openIssue(config, event, callback)

module.exports = PivotalTracker
