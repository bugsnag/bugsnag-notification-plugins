fs = require "fs"
path = require "path"
sugar = require "sugar"
handlebars = require "handlebars"
optimist = require "optimist"


#
# The base Bugsnag NotificationPlugin class
# Extend this class to create your own Bugsnag notification plugins:
#
#   NotificationPlugin = require "../../notification-plugin.coffee"
#   class MyPlugin extends NotificationPlugin
#     @receiveEvent = (config, event) ->
#       ...
#   module.exports = MyPlugin
#
# All notification plugins must override the receiveEvent function to perform
# the notification. This method is fired when a new event is triggered.
#
# See https://github.com/bugsnag/bugsnag-notification-plugins/ for full docs
#

class NotificationPlugin
  # Fired when a new event is triggered for notification
  # Plugins MUST override this method
  @receiveEvent: (config, event, callback) ->
    throw new Error("Plugins must override receiveEvent")

  # Fire a test event to your notification plugin (do not override)
  @fireTestEvent: (config, triggerType, callback) ->
    triggerType ||= "firstException"
    event = require "./example-events/#{triggerType}"

    @receiveEvent config, event, callback

  # Configuration validation methods (do not override)
  @validateConfig = (config, pluginConfigFile) ->
    require(pluginConfigFile).fields.each (option) ->
      # Fill in default values
      if !config[option.name]? && option.defaultValue?
        config[option.name] = option.defaultValue

      # Validate all non-optional config fields are present
      if !config[option.name]? && !option.optional?
        throw new Error("ConfigurationError: Required configuration option '#{option.name}' is missing")

      # Validate fields with allowed values
      if config[option.name]? && option.allowedValues?.none(config[option.name])
        throw new Error("ConfigurationError: Invalid value for '#{option.name}'")

  # Plain-text stacktrace summary
  @basicStacktrace = (stacktrace) ->
    summaryStacktrace(stacktrace).map((line) ->
      stacktraceLineString line
    , this).join "\n"

  # Returns the first line of a stacktrace (formatted)
  @firstStacktraceLine = (stacktrace) ->
    stacktraceLineString summaryStacktrace(stacktrace)[0]

  # An error title, eg "Exception in dashboard#payments"
  @title = (event) ->
    event.error.exceptionClass + " in " + event.error.context

  # A markdown-formatted error description
  @markdownBody = (event) ->
    markdownTemplate event

  # An html-formatted error description
  @htmlBody = (event) ->
    htmlTemplate event

  # A plan-text error description
  @textBody = (event) ->
    textTemplate event

  # Utility methods for http requests
  @request: require("superagent")


  #
  # Internal/utility functions
  #

  # Change a stackframe object into a string
  stacktraceLineString = (stacktraceLine) ->
    stacktraceLine.file + ":" + stacktraceLine.lineNumber + " - " + stacktraceLine.method

  # Utility to determine whether a stacktrace line is `inProject`
  inProjectStacktraceLine = (line) ->
    line? and "inProject" of line and line.inProject

  # Utility for getting all the stacktrace lines that are `inProject`
  summaryStacktrace = (stacktrace) ->
    filtered = undefined

    # If there are no 'inProject' stacktrace lines
    filtered = stacktrace.slice(0, 3)  unless (filtered = stacktrace.filter(inProjectStacktraceLine)).length
    filtered

  # Handlebars templates for error descriptions
  markdownTemplate = handlebars.compile(fs.readFileSync(__dirname + "/templates/error.md.hbs", "utf8"))
  htmlTemplate = handlebars.compile(fs.readFileSync(__dirname + "/templates/error.html.hbs", "utf8"))
  textTemplate = handlebars.compile(fs.readFileSync(__dirname + "/templates/error.text.hbs", "utf8"))

  # Template helpers
  handlebars.registerHelper "eachSummaryFrame", (stack, options) ->
    summaryStacktrace(stack).map((line) -> options.fn line).join("")


module.exports = NotificationPlugin


# If running plugins from the command line, allow them to fire test events
if module.parent && !module.parent.parent?
  # Parse command line flags
  config = Object.reject(optimist.argv, "_", "$0", "triggerType")

  # Validate configuration
  try
    NotificationPlugin.validateConfig config, path.dirname(module.parent.filename) + "/config.json"
  catch err
    return console.error(err.message)

  # Fire a test event
  plugin = require(module.parent.filename)
  plugin.fireTestEvent config, optimist.argv.triggerType, (err, data) ->
    if err
      console.error "Error firing notification", err
    else
      console.log "Fired test event successfully"
      console.log data if data?
