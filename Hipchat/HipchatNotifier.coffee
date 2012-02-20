hipchat = require("node-hipchat")
notification_require = require "../"

class exports.Notification extends notification_require.NotificationBase
    # Notifier
    executeNotification: (callback) =>
        @projectHandle.fetch (err, project) =>
            return callback(err) if err?
            @errorUrl (err, url) =>
                return callback(err) if err?
                client = new hipchat(@configuration.apiKey)
                client.postMessage({
                    room: @configuration.room
                    from: "Bugsnag"
                    message: "#{@event.exceptions[0].errorClass} in #{@event.context} - <a href=#{url}>View here</a>"
                    notify: true
                    color: @configuration.color
                })