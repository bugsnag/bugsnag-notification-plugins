request = require("request")

# Notifier
exports.executeNotification = (account, project, triggerText, event, options) ->
    request.post(options.url, {
        some: "payload"
    })