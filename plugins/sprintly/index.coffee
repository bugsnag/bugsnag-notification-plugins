NotificationPlugin = require "../../notification-plugin"

class Sprintly extends NotificationPlugin
  @receiveEvent = (config, event) ->
    user_email = config?.sprintlyEmail
    api_key = config?.apiKey
    project_id = config?.projectId
    sprintly_status = config?.sprintlyStatus

    # Build the Sprint.ly API request
    # API documentation: https://sprintly.uservoice.com/knowledgebase/articles/98412-items
    description = 
    """
    *#{event.error.exceptionClass}* in *#{event.error.context}*
    #{event.error.message if event.error.message}
    #{event.error.url}
    """

    query_object =
      type: "defect"
      title: "#{event.error.exceptionClass} in #{event.error.context}"
      tags: "bugsnag"
      description: description
      status: sprintly_status

    @request
      .post("https://sprint.ly/api/products/#{project_id}/items.json")
      .query(query_object)
      .auth(user_email, api_key)
