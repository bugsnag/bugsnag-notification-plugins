NotificationPlugin = require "../../notification-plugin"

class Unfuddle extends NotificationPlugin

  priorityMap =
    lowest: 1
    low: 2
    normal: 3
    high: 4
    highest: 5

  @ticketsUrl = (config) ->
    "https://#{config.subdomain}.unfuddle.com/api/v1/projects/#{config.project}/tickets"

  @requestPayload = (config, event) ->
    """
      <ticket>
        <summary>#{@title event}</summary>
        <description><![CDATA[#{@markdownBody event}]]></description>
        <priority>#{priorityMap[config.priority]}</priority>
      </ticket>
    """

  @receiveEvent = (config, event, callback) ->
    @request
      .post @ticketsUrl config
      .auth config.username, config.password
      .set 'Accept', 'application/json'
      .set 'Content-Type', 'application/xml'
      .send @requestPayload config, event
      .end (res) ->
        return callback res.error if res.error
        callback null,
          url: res.header['location']

module.exports = Unfuddle
