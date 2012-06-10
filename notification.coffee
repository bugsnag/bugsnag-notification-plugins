request = require "superagent"

class Bugsnag.Notification
  shortMessage: (reason, projectName, error) ->
    "[#{reason} on #{projectName}] #{error.exceptionClass}: #{error.message.substr(0,10)}"

  httpPost: (url, params) ->
    request
      .post url
      .send params
      .end (res) ->
        console.log "got a response"

  fireTestEvent: () ->
    @receiveEvent

  receiveEvent: (reason, projectName, error) ->
    throw "Plugins must override receiveEvent"