NotificationPlugin = require '../../notification-plugin'
url = require 'url'

module.exports = class TargetProcess extends NotificationPlugin

  # Resolve the bugs rest api endpoint
  bugsUrl = (config) ->
    url.resolve config.url, 'api/v1/Bugs'

  # Resolve the url that points to the entity
  entityUrl = (config, entityId) ->
    url.resolve config.url, "entity/#{entityId}"

  # Build the request payload
  @requestPayload = (config, event) ->
    payload =
      name: @title event
      description: @htmlBody event
      project: id: config.projectId

    # If a teamId is specified, add it to the payload
    payload.team = id: config.teamId if config.teamId?

    payload

  # Receive the configuration & event payload
  @receiveEvent = (config, event, callback) ->
    return if event?.trigger?.type == 'reopened'

    @request
      .post bugsUrl config
      .type 'json'
      .auth config.username, config.password
      .send @requestPayload config, event
      .on 'error', (err) ->
        callback err
      .end (res) ->
        return callback res.error if res.error

        # Respond back to the callback
        callback null,
          id: bugId = res?.body?.Id
          url: entityUrl config, bugId
