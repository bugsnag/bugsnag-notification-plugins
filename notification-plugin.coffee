sugar   = require "sugar"
request = require "superagent"
fs      = require "fs"
path    = require "path"

class NotificationPlugin
  @shortMessage: (reason, projectName, error) ->
    "[#{reason} on #{projectName}] #{error.exceptionClass}: #{error.message.substr(0,10)}"

  @httpGet: (url, params, callback) ->
    request.get(url).send(params).end(callback)

  @httpPost: (url, params, callback) ->
    request.post(url).send(params).type("form").end(callback)

  @httpPostJson: (url, obj, callback) ->
    request.post(url).send(obj).end(callback)

  @fireTestEvent: (config) ->
    reason = "First exception"
    projectName = "Example"
    error =
      "exceptionClass": "RuntimeError"
      "message": "Something really bad happened"
      "context": "home#example"
      "appVersion": "1.0.0"
      "releaseStage": "production"
      "firstStacktraceLine": "app/example_controller.rb:87 - example"
      "totalOccurrences": 5
      "usersAffected": 5
      "contextsAffected": 1
      "firstReceived": new Date()
      "eventUrl": "http://www.bugsnag.com/blah"

    @receiveEvent(config, reason, projectName, error)

  @validateConfig: (config, pluginConfigFile) ->
    pluginConfig = JSON.parse(fs.readFileSync(pluginConfigFile, "ascii"))
    for option in pluginConfig.options
      configValue = config[option.name]

      # Validate all non-optional config options are present
      @configError("Missing '#{option.name}'") unless configValue or option.optional

      # Validate fields with allowed values
      @configError("Invalid value for '#{option.name}'") if configValue and option.allowedValues and option.allowedValues.none(configValue)

  @configError: (message) ->
    throw new Error("ConfigurationError: #{message}")

  @receiveEvent: (reason, projectName, error) ->
    throw new Error("Plugins must override receiveEvent")



# Export the plugin class for requiring
module.exports = NotificationPlugin


# If running plugins from the command line, allow them to fire test events
if module.parent and module.parent.parent == null
  argv = require("optimist").argv
  flags = Object.keys(argv).exclude("_", "$0")

  if flags.length > 0
    config = {}
    for key in flags
      config[key] = argv[key]

    NotificationPlugin.validateConfig(config, "#{path.dirname(module.parent.filename)}/config.json")
    plugin = require(module.parent.filename)
    plugin.fireTestEvent(config)