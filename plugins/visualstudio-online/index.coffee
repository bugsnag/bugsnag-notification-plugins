NotificationPlugin = require "../../notification-plugin"

class VisualStudioIssue extends NotificationPlugin
  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"


#
#    "title": @title(event)
#    "content": @markdownBody(event)
#    "kind": config.kind
#    "priority": config.priority
#

    query_object = [

        {
         "op":"add",
         "path": "/fields/System.Title",
         "value": @title(event)
        },
        {
            "op":"add",
            "path":"/fields/Microsoft.VSTS.TCM.ReproSteps"
            "value":@htmlBody(event)
        }
    ]

    # Send the request
    @request
      .patch( "https://#{config.account}.visualstudio.com/defaultcollection/#{config.project}/_apis/wit/workitems/$bug?api-version=1.0-preview.2")
      .timeout(40000)
      .auth(config.username, config.password)
       .set('Content-Type', 'application/json-patch+json')
      .set('Accept', 'application/json')
      .send(JSON.stringify(query_object))
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        return callback({status: res.error.status, message: res.error.message, body: res.body}) if res.error

        callback null,
          id: res.body.id
          url:  "https://#{config.account}.visualstudio.com/defaultcollection/#{config.project}/_workitems#_a=edit&id=#{res.body.id}"

module.exports = VisualStudioIssue
