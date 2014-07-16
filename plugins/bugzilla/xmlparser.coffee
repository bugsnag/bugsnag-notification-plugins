xml2js = require 'xml2js'

class XmlResponseParser

  @parse: (json, callback) ->
    parser = new xml2js.Parser(ignoreAttrs: true, explicitArray: false)
    parser.parseString(json.res.text, callback)

module.exports = XmlResponseParser
