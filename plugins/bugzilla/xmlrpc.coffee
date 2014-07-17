NotificationPlugin = require '../../notification-plugin'
xmlBuilder = require './xmlBuilder'
xmlResponseParser = require './xmlparser'

class XmlRpc

  constructor: (@host) ->

  buildRequest: (xmlBody) ->
    NotificationPlugin.request
      .post(@host + '/xmlrpc.cgi')
      .type('text/xml')
      .send(xmlBody)
      .on 'error', (err) ->
        callback(err)

  methodCall: (methodName, params, callback, tokenCallback) ->
    xmlBody = xmlBuilder.buildRequestBody(methodName, params)
    request = @buildRequest(xmlBody)
    request.end (response) =>
      return callback(response.error) if response.error
      xmlResponseParser.parse response, (xmlError, xmljson) =>
        callback(xmlError) if xmlError
        if fault = xmljson.methodResponse.fault
          errorMsg = fault.value.struct.member[0].value.string
          errorCode = fault.value.struct.member[1].value.int
          callback(new Error("#{errorMsg} (code: #{errorCode})"))

        if tokenCallback
          tokenCallback(@extractToken(xmljson))
        else
          id = @extractId(xmljson)
          callback null,
            id: id,
            url: "#{@host}/show_bug.cgi?id=#{id}"

  extractToken: (xmljson) ->
    xmljson.methodResponse.params.param.value.struct.member[1].value.string

  extractId: (xmljson) ->
    xmljson.methodResponse.params.param.value.struct.member.value.int

module.exports = XmlRpc;
