NotificationPlugin = require '../../notification-plugin'

module.exports = class ActiveCollab extends NotificationPlugin

  visibilityMap =
    'Private': 0
    'Normal': 1

  priorityMap =
    'Highest': 2
    'High': 1
    'Normal': 0
    'Low': -1
    'Lowest': -2

  @receiveEvent: (config, event, callback) ->

    if event?.trigger?.type == "linkExistingIssue"
      return callback(null, null)

    return if event?.trigger?.type == 'reopened'

    @request
      .post config.apiUrl
      .query
        path_info: "projects/#{config.projectSlug}/tasks/add"
        auth_api_token: config.apiToken
      .set 'Accept', 'application/json'
      .field 'task[name]', @title event
      .field 'task[body]', @htmlBody event
      .field 'task[priority]', "#{priorityMap[config.priority]}"
      .field 'task[visibility]', "#{visibilityMap[config.visibility]}"
      .field 'submitted', 'submitted'
      .on 'error', (err) -> callback err
      .end (res) ->
        return callback res.error if res.error

        callback null,
          id: res.body.id
          url: res.body.permalink
