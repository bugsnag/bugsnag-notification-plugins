NotificationPlugin = require "../../notification-plugin"

class Hipchat extends NotificationPlugin
  HIPCHAT_API_ENDPOINT = "https://api.hipchat.com/v1/rooms/message"

  @receiveEvent: (config, reason, projectName, error) ->
    # Build the request
    params = 
      from: "Bugsnag"
      message: @shortMessage reason, projectName, error
      auth_token: config.authToken
      room_id: config.roomId
      notify: config.notify || false
      color: config.color || "yellow"

    # Send the request to hipchat
    @httpPost HIPCHAT_API_ENDPOINT, params

module.exports = Hipchat