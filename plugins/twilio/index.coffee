NotificationPlugin = require "../../notification-plugin"

class Twilio extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    # Build the message
    message = "[#{event.project.name}] #{event.trigger.message}"
    if event.trigger.type == 'projectSpiking'
      message += ": #{event.trigger.rate} exceptions/minute"
    else if event.error
      message += ": #{event.error.exceptionClass} in #{event.error.context}"

    # Build the request
    params = 
      From: config.fromNumber
      To: config.toNumber
      Body: message

    # Send the request to hipchat
    @request
      .post("https://api.twilio.com/2010-04-01/Accounts/#{config.accountSid}/SMS/Messages.xml")
      .timeout(4000)
      .send(params)
      .auth(config.accountSid, config.authToken)
      .type("form")
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        callback(res.error)

module.exports = Twilio
