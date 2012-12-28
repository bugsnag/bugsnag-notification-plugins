NotificationPlugin = require "../../notification-plugin"

class Jira extends NotificationPlugin
  @receiveEvent: (config, event) ->
    if event.error
      
      description = [event.error.context, event.error.firstReceived ];

      event.error.stacktrace.forEach( (stack)  ->
        description.push("--------------------\n
        file: " + stack.file + "\n
        line number: " + stack.lineNumber + "\n
        method: " + stack.method + "\n
        --------------------");
      )
      
      description.push(event.error.url);

      params =
        fields:
          project: 
            key: config.projectKey
          summary: [event.error.releaseStage.toUpperCase(), event.trigger.message, event.error.message].join(' ')
          description: description.join("\n\n")
          issuetype:
            name: config.issueType



          
      url = config.host + "/rest/api/2/issue"

      # Send the request to campfire
      @request
        .post(url)
        .auth(config.username, config.password)
        .set('Content-Type', 'application/json')
        .set('Accept', 'application/json')
        .send(params)
        .end( (res) ->
          #console.log(res)
        )

module.exports = Jira