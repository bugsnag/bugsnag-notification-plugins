NotificationPlugin = require "../../notification-plugin"

class Email extends NotificationPlugin
  SIDEKIQ_WORKER = "ErrorEmailWorker"
  SIDEKIQ_QUEUE = "error_emails"

  @receiveEvent: (config, event, opts) ->
    opts.sidekiq.enqueue SIDEKIQ_WORKER, [event.trigger.type, event.error.id, config?.includeMetadata], 
      retry: false
      queue: SIDEKIQ_QUEUE

module.exports = Email