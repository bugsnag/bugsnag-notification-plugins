NotificationPlugin = require '../../notification-plugin.js'
url = require 'url'

class Hall extends NotificationPlugin

  # End API access endpoint
  API_URL = 'https://hall.com/api/1/'

  # The image that displays for Bugsnag messages
  BUGSNAG_AVATAR = 'https://bugsnag.com/favicon96.png'

  # Gets the url to the message integration
  @chatUrl: (config) ->
    url.resolve API_URL, "services/generic/#{config.apiToken}"

  # Gets the body of the chat message
  @messageBody: Handlebars.compile(
    '{{#if error.message}}' +
      '{{error.message}} (<a href="{{error.url}}">details</a>)' +
    '{{else}}' +
      '<b>{{trigger.message}}</b> from <a href="{{project.url}}">{{project.name}}</a>' +
    '{{/if}}'
  )

  # Build the request body
  @messagePayload = (config, event) ->
    title: @title event
    message: @messageBody event
    picture: BUGSNAG_AVATAR

  # Fire the event
  @receiveEvent = (config, event, callback) ->
    @request
      .post @chatUrl config
      .type 'json' # Content-Type: application/json
      .send @messagePayload config, event
      .on 'error', (err) ->
        callback err
      .end (res) ->
        callback res.error if res.error or null

module.exports = Hall