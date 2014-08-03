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

  @apiUrl: (config, path) ->
    "#{config.apiUrl}?path_info=#{encodeURIComponent path}&auth_api_token=#{config.apiToken}"

  @getProject: (config, callback) ->
    @request
      .get @apiUrl config, 'projects'
      .query format: 'json'
      .on 'error', (err) -> callback err
      .end (res) ->
        return callback res.error if res.error

        # Find the project(s) that match the project name
        matches = res.body.filter (project) ->
          project.name is config.project

        # Which one do we pick if there multiple matches?
        return callback Error 'Multiple projects matches' if matches.length > 1

        # Return the first matched project
        callback null, matches[0]

  @receiveEvent: (config, event, callback) ->
    @getProject config, (err, project) =>
      return callback err if err

      @request
        .post @apiUrl config, "projects/#{project.id}/tasks/add"
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
