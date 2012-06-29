NotificationPlugin = require "../../notification-plugin"

class Twilio extends NotificationPlugin
  @receiveEvent: (config, event) ->
    # Build the message
    message = "[#{event.project.name}] #{event.trigger.message}"
    if event.error
      message += ": #{event.error.exceptionClass} in #{event.error.context}"
    
    # Build the request
    params = 
      From: config.fromNumber
      To: config.toNumber
      Body: message

    # Send the request to hipchat
    @request
      .post("https://api.twilio.com/2010-04-01/Accounts/#{config.accountSid}/SMS/Messages.xml")
      .send(params)
      .auth(config.accountSid, config.authToken)
      .type("form")
      .end()

module.exports = Twilio