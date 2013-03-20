NotificationPlugin = require "../../notification-plugin"

class Email extends NotificationPlugin
  SIDEKIQ_WORKER = "ErrorEmailWorker"
  SIDEKIQ_QUEUE = "error_emails"

  @receiveEvent: (config, event, callback) ->
    sidekiq = config.sidekiq
    delete config.sidekiq

    sidekiq.enqueue SIDEKIQ_WORKER, [event.trigger.type, event.error.id, config],
      retry: false
      queue: SIDEKIQ_QUEUE

    callback null

module.exports = Email