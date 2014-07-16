class XmlBuilder

  @buildRequestBody: (methodName, params) ->
    method = '<?xml version="1.0"?>'
    method += '<methodCall>'
    method += '<methodName>' + methodName + '</methodName><params>'
    i = 0
    while i < params.length
      method += '<param>' + @buildValue(params[i]) + '</param>'
      i++
    method += '</params></methodCall>'

  @buildStruct: (members) ->
    struct = '<struct>'
    for key of members
      struct += '<member><name>' + key + '</name>' +
        @buildValue(members[key]) + '</member>'
    struct += '</struct>'

  @buildArray: (values) ->
    array = '<array><data>'
    i = 0
    while i < values.length
      array += @buildValue(values[i])
      i++
    array += '</data></array>'

  @buildValue: (val) ->
    value = '<value>'
    switch typeof(val)
      when 'number'
        value += '<int>' + val + '</int>'
      when 'string'
        value += '<string>' + val + '</string>'
      when 'boolean'
        value += '<boolean>' + val + '</boolean>'
      when "object"
        if val instanceof Array
          value += @buildArray(val)
        else
          value += @buildStruct(val)
    value += '</value>'

module.exports = XmlBuilder
