NotificationPlugin = require "../../notification-plugin"

class Webhook extends NotificationPlugin
  @receiveEvent: (config, reason, project, error) ->
    # Build the request
    params = 
      reason: reason
      project: project
      error: error

    # Send the request to the url
    @httpPostJson config.url, params

module.exports = Webhook