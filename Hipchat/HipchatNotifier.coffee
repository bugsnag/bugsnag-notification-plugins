hipchat = require("node-hipchat")
notification_require = require "../"

class exports.Notification extends notification_require.NotificationBase
    # Notifier
    executeNotification: (callback) =>
        @projectHandle.fetch (err, project) =>
            return callback(err) if err?
            @errorUrl (err, url) =>
                @trigger.getLongExplanation (explanation) =>
                    return callback(err) if err?
                    client = new hipchat(@configuration.apiKey)
                    client.postMessage({
                        room: @configuration.room
                        from: "Bugsnag"
                        message: "#{explanation} in #{project.name} - #{url}"
                        notify: true
                        color: @configuration.color
                    })