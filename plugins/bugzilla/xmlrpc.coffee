NotificationPlugin = require '../../notification-plugin'
xmlBuilder = require './xmlBuilder'
xmlResponseParser = require './xmlparser'

class XmlRpc

  host: 'https://bugzilla.mozilla.org/'

  setHost: (@host) ->

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
        @handleErrors(xmlError, xmljson.methodResponse.fault)
        if tokenCallback
          tokenCallback(@extractToken(xmljson))
        else
          id = xmljson.methodResponse.params.param.value.struct.member.value.int
          callback null,
            id: id,
            url: "#{@host}/show_bug.cgi?id=#{id}"


  handleErrors: (xmlError, fault) ->
    callback(xmlError) if xmlError
    if fault
      errorMsg = fault.value.struct.member[0].value.string
      errorCode = fault.value.struct.member[1].value.int
      callback(new Error("#{errorMsg} (code: #{errorCode})"))

  extractToken: (xmljson) ->
    xmljson.methodResponse.params.param.value.struct.member[1].value.string

module.exports = new XmlRpc;
