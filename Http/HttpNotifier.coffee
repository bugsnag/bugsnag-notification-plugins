request = require("request")

# Notifier
exports.executeNotification = (account, project, triggerText, event, options, target, errorCallback) ->
    request.post(options.url, {
        some: "payload"
    })