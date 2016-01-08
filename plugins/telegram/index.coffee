

NotificationPlugin = require "../../notification-plugin.coffee"

class Telegram extends NotificationPlugin
  @openIssue = (config, event, callback) ->
      @request
      .get('https://api.telegram.org/bot'+config.token+'/sendMessage?chat_id='+config.chatId+'&text= Client: '+encodeURIComponent(event.project.name)+'%0AMessage: '+encodeURIComponent(event.error.message)+'%0AFirst Received: '+encodeURIComponent(event.error.firstReceived)+'%0ARelease Stage: '+encodeURIComponent(event.error.releaseStage))
      .on "error", (err) ->
          callback(err)
        .end (res) ->
          return callback(res.code) if res.code
          callback null,
            id: res.id

  @receiveEvent: (config, event, callback) ->

    if event?.error?.releaseStage? ==! "production"
      return callback(null, null)

    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)

    @openIssue(config, event, callback)

module.exports = Telegram
