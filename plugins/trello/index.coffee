NotificationPlugin = require "../../notification-plugin"

class Trello extends NotificationPlugin
  stacktraceLines = (stacktrace) ->
    console.log line for line in stacktrace when line.inProject
    ("#{line.file}:#{line.lineNumber} - #{line.method}" for line in stacktrace when line.inProject isnt false)

  @getListId: (config, callback) ->
    @request
      .get("https://api.trello.com/1/boards/#{config?.boardId}/lists?key=#{config?.applicationKey}&token=#{config?.memberToken}")
      .timeout(4000)
      .on("error", callback)
      .end (res) ->
        return callback(res.error) if res.error

        callback null, res.body.find((el) -> el.name == config?.listName)?.id

  @receiveEvent: (config, event, callback) ->
    return if event?.trigger?.type == "reopened"
    
    # Would be nice to save this list Id for repeated calls
    @getListId config, (err, listId) =>
      return callback(err) if err

      data =
        "key": config?.applicationKey
        "token": config?.memberToken
        "idList": listId
        "name": "#{event.error.exceptionClass} in #{event.error.context}"
        "due": null
        "labels": config?.labels?.split(',')
        "desc":
          """
          *#{event.error.exceptionClass}* in *#{event.error.context}*
          #{event.error.message if event.error.message}
          #{event.error.url}

          *Stacktrace:*
          #{stacktraceLines(event.error.stacktrace).join("\n")}
          """

      @request
        .post("https://api.trello.com/1/cards")
        .send(data)
        .on "error", (err) ->
          callback(err)
        .end (res) ->
          return callback(res.error) if res.error

          callback null,
            id: res.body.id
            url: res.body.url

module.exports = Trello
