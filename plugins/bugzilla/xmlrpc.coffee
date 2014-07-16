NotificationPlugin = require '../../notification-plugin'
xmlBuilder = require './xmlBuilder'
xmlResponseParser = require './xmlparser'

class XmlRpc

  host: 'https://bugzilla.mozilla.org/'

  setHost: (@host) ->

  methodCall: (request, methodName, params, callback) ->
    xmlBody = xmlBuilder.buildRequestBody(methodName, params)
    request = request.post(@host + '/xmlrpc.cgi').type('text/xml').send(xmlBody)
    request.on 'error', (err) ->
      throw err
    request.end (response) =>
      @getResponse(response, callback)

  getResponse: (response, callback) ->
    xmlResponseParser.parse response, (err, xmljson) =>
      throw err if err

      if fault = xmljson.methodResponse.fault
        @handleFault(fault)

      if callback
        token = @extractToken(xmljson)
        callback(token)

  handleFault: (fault) ->
    faultMeta = (idx) ->
      fault.value.struct.member[idx].value
    errorMsg = faultMeta(0).string
    errorCode = faultMeta(1).int
    throw new Error("#{errorMsg} (code: #{errorCode})")

  extractToken: (xmljson) ->
    xmljson.methodResponse.params.param.value.struct.member[1].value.string

module.exports = new XmlRpc;
