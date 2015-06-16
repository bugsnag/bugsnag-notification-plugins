NotificationPlugin = require "../../notification-plugin"

class Pushed extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    # Build the message
    message = "[#{event.project.name}] #{event.trigger.message}"
    if event.error
      message += ": #{event.error.exceptionClass} in #{event.error.context}"
    
    # Build the request
    params = 
      content: message
      content_extra: event.error.url
      pushed_id: config.pushed_id

    # Send the request to hipchat
    @request
      .post("https://api.pushed.co/integrations/bugsnag")
      .timeout(4000)
      .send(params)
      .type("form")
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

module.exports = Pushed