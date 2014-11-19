fs = require "fs"
sugar = require "sugar"
handlebars = require "handlebars"


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

  # Fire a test event to your notification plugin (do not override)
  @fireTestEvent: (config, callback) ->
    event =
      error:
        exceptionClass: "ExampleException"
        message: "Something really bad happened"
        context: "home#example"
        appVersion: "1.0.0"
        releaseStage: "production"
        occurrences: 42
        firstReceived: new Date()
        usersAffected: 20
        url: "http://bugsnag.com/errors/example/events/example"
        stacktrace: [
          {
            file: "app/controllers/home_controller.rb"
            lineNumber: 123
            method: "example"
            inProject: true
          }
          {
            file: "app/controllers/other_controller.rb"
            lineNumber: 12
            method: "broken"
            inProject: true
          }
          {
            file: "gems/junk/junkfile.rb"
            lineNumber: 999
            method: "something"
            inProject: false
          }
          {
            file: "lib/important/magic.rb"
            lineNumber: 4
            method: "load_something"
            inProject: true
          }
        ]

      project:
        name: "Example.com"
        url: "http://bugsnag.com/projects/example"

      trigger:
        type: "firstException"
        message: "New exception"

    if config.spike
      delete config.spike
      event.trigger =
        type: "projectSpiking"
        message: "Project Spiking"
        rate: 103

    if config.comment
      delete config.comment
      event.trigger =
        type: "comment"
        message: "Comment Added"
      event.comment =
        message: "I think this should be easy to fix"
      event.user =
        name: "John Smith"

    @receiveEvent config, event, callback


  # Configuration validation methods (do not override)
  @validateConfig = (config, pluginConfigFile) ->
    fs = require("fs")
    pluginConfig = JSON.parse(fs.readFileSync(pluginConfigFile, "ascii"))
    if pluginConfig.fields
      pluginConfig.fields.each (option) ->
        configValue = config[option.name]

        # Validate all non-optional config fields are present
        throw new Error("ConfigurationError: Required configuration option '" + option.name + "' is missing")  unless configValue isnt `undefined` or option.optional or (option.type is "boolean" and option.defaultValue isnt `undefined`)

        # Validate fields with allowed values
        throw new Error("ConfigurationError: Invalid value for '" + option.name + "'")  if configValue isnt `undefined` and option.allowedValues and option.allowedValues.none(configValue)

        # Fill in default values
        config[option.name] = option.defaultValue  if not configValue? and option.defaultValue isnt `undefined`


module.exports = NotificationPlugin

# If running plugins from the command line, allow them to fire test events
if module.parent and module.parent.parent is null
  path = require("path")
  argv = require("optimist").argv

  # Parse command line flags
  flags = Object.keys(argv).exclude("_", "$0")
  config = {}
  flags.each (flag) ->
    config[flag] = argv[flag]  if argv[flag]? and argv[flag] isnt ""
    return


  # Validate configuration
  try
    NotificationPlugin.validateConfig config, path.dirname(module.parent.filename) + "/config.json"
  catch err
    return console.error err.message

  # Fire a test event
  plugin = require(module.parent.filename)
  plugin.fireTestEvent config, (err, data) ->
    if err
      console.error "Error firing notification\n", err
    else
      console.log "Fired test event successfully\n", data
