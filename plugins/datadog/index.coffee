NotificationPlugin = require "../../notification-plugin"

class Datadog extends NotificationPlugin
    @receiveEvent = (config, event, callback) ->

        # Refer to http://docs.datadoghq.com/api/#events
        payload = {
            title: null, # Event title; limited to 100 characters.
            text: null, # Body of event; limited to 4000 characters.
            priority: "normal", # Only 'normal' or 'low'
            tags: [], # Ex: environment:production
            alert_type: "info", # Only 'error', 'warning', or 'info'
            source_type_name: "Bugsnag"
        }

        # Default text body... just give a link to the bugsnag error
        payload.text = "#{event.error.url}"

        # Add some tags
        if event.error.appVersion
            payload.tags << "app-version:#{event.error.appVersion}"
        if event.error.releaseStage
            payload.tags << "release-stage:#{event.error.releaseStage}"

        if event.error.severity == "info"
            payload.priority = "low"
            payload.alert_type = "info"
        else if event.error.severity == "warning"
            payload.priority = "low"
            payload.alert_type = "warning"
        else
            payload.alert_type = "error"

        if event.trigger.type == "comment"
            payload.alert_type = "info"
            payload.title = event.user.name + " commented on " +
                event.error.exceptionClass
            if event.error.message
                payload.text = event.error.message + " - " + payload.text
        else if event.trigger.type == "projectSpiking"
            payload.title = "Spike of " + event.trigger.rate +
                " exceptions/minute from " + event.project.name
        else
            payload.title = event.trigger.message + " in " +
                event.error.releaseStage + " from " +
                event.project.name

        @request
            .post("https://app.datadoghq.com/api/v1/events?api_key=" + config.api_key)
            .set('Content-Type', 'application/json')
            .timeout(4000)
            .send(payload)
            .on "error", (err) ->
                callback(err)
            .end (res) ->
                callback(res.error)

module.exports = Datadog
