NotificationPlugin = require "../../notification-plugin"

class OnTime extends NotificationPlugin

  accessTokenRequestParameters = (config) ->
    "grant_type=password&scope=read write" +
    "&client_id=#{config.clientid}" +
    "&client_secret=#{config.clientsecret}" +
    "&username=#{config.username}&password=#{config.password}"

  stacktraceLines = (stacktrace) ->
    stacktrace = NotificationPlugin.getInProjectStacktrace stacktrace
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace)

  itemDescription = (event) ->
    """
    #{event.trigger.message} in #{event.project.name}.<br />
    #{event.error.exceptionClass} in #{event.error.context}.<br />
    #{event.error.message if event.error.message}.<br /><br />
    <a href=#{event.error.url}>View bug on bugsnag.com</a><br /><br /><br />
    Stacktrace:<br />
        #{NotificationPlugin.basicStacktrace(event.error.stacktrace)}<br /><br />
    <a href=#{event.error.url}>View full stacktrace</a><br />
    """

  itemRequestData = (config, event) ->
    item:
      name: "#{event.error.exceptionClass} in #{event.error.context}"
      description: itemDescription(event)
      project:
        id: "#{config.projectId}"

  findProjectIds = (object, project, ids) ->
    for key, value of object
      if (key == "name" && value == project)
        ids.push(object.id)
      else if typeof(value) == "object"
        findProjectIds value, project, ids

    return ids

  @getToken: (config, callback) =>
    @request
      .post("#{config.url}/api/v2/oauth2/token")
        .set('Accept', 'application/json')
        .send(accessTokenRequestParameters(config))
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          return callback(res.error) if res.error

          # If we got a valid token
          if res && res.body && res.body.access_token
            config.access_token = res.body.access_token
            callback null
          else
            callback 'Unable to obtain access token.'

  @getProject: (config, callback) =>
    return if event?.trigger?.type == "reopened"
    
    @request
      .get("#{config.url}/api/v2/projects?access_token=#{config.access_token}")
      .timeout(4000)
        .set('Accept', 'application/json')
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          return callback(res.error) if res.error

          # If we got a response
          # traverse all project and find id by project name
          ids = []
          findProjectIds res.body, config.project, ids

          # Set project Id, if we found exactly one match
          if ids.length == 1
            config.projectId = ids[0]
            callback null
          else
            callback 'Project name must exist in OnTime and be a unique value.'

  @postItem: (config, event, callback) =>
    itemType = config.itemType.split " "
    @request
      .post("#{config.url}/api/v2/#{itemType[0]}?access_token=#{config.access_token}")
        .set('Accept', 'application/json')
        .send(itemRequestData(config, event))
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          return callback(res.error) if res.error

          # If we got a response, then we are done
          callback null,
            id: res.body.data.id
            url: "#{config.url}/api/v2/#{itemType[0]}/#{res.body.data.id}"

  # Do all the heavy lifting
  @receiveEvent: (config, event, callback) ->
    # Step 1. Get token
    @getToken config, (err) =>
      return callback(err) if err

      # Step 2. Get project
      @getProject config, (err) =>
        return callback(err) if err

        # Step 3. Create item
        @postItem config, event, (err) =>
          return callback(err) if err

module.exports = OnTime
