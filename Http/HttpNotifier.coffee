request = require("request")
notification_require = require "../"

class exports.Notification extends notification_require.NotificationBase
    # Notifier
    executeNotification: (callback) =>
        request.post(@configuration.url, {
            some: "payload"
        })