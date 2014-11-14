require "sugar"
fs = require("fs")
Handlebars = require("handlebars")

Handlebars.registerHelper "eachSummaryFrame", (stack, options) ->
  NotificationPlugin.getSummaryStacktrace(stack).map((line) ->
    options.fn line
  ).join ""

#
# The base Bugsnag NotificationPlugin class
# Extend this class to create your own Bugsnag notification plugins:
#
#   NotificationPlugin = require "../../notification-plugin.js"
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

NotificationPlugin = (->
  NotificationPlugin = ->

  # Load templates
  NotificationPlugin.markdownTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.md.hbs", "utf8"))
  NotificationPlugin.htmlTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.html.hbs", "utf8"))
  NotificationPlugin.textTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.text.hbs", "utf8"))

  # Fired when a new event is triggered for notification
  # Plugins MUST override this method
  NotificationPlugin.receiveEvent = (config, event, callback) ->
    throw new Error("Plugins must override receiveEvent")


  # Utility methods for generating notification content
  NotificationPlugin.stacktraceLineString = (stacktraceLine) ->
    stacktraceLine.file + ":" + stacktraceLine.lineNumber + " - " + stacktraceLine.method

  NotificationPlugin.basicStacktrace = (stacktrace) ->
    @getSummaryStacktrace(stacktrace).map((line) ->
      @stacktraceLineString line
    , this).join "\n"


  # Returns the first line of a stacktrace (formatted)
  NotificationPlugin.firstStacktraceLine = (stacktrace) ->
    @stacktraceLineString @getSummaryStacktrace(stacktrace)[0]


  # Utility to determine whether a stacktrace line is `inProject`
  NotificationPlugin.inProjectStacktraceLine = (line) ->
    line? and "inProject" of line and line.inProject


  # Utility for getting all the stacktrace lines that are `inProject`
  NotificationPlugin.getSummaryStacktrace = (stacktrace) ->
    filtered = undefined

    # If there are no 'inProject' stacktrace lines
    filtered = stacktrace.slice(0, 3)  unless (filtered = stacktrace.filter(@inProjectStacktraceLine)).length
    filtered

  NotificationPlugin.title = (event) ->
    event.error.exceptionClass + " in " + event.error.context

  NotificationPlugin.markdownBody = (event) ->
    @markdownTemplate event

  NotificationPlugin.htmlBody = (event) ->
    @htmlTemplate event

  NotificationPlugin.textBody = (event) ->
    @textTemplate event


  # Utility methods for http requests
  NotificationPlugin.request = require("superagent")

  # Fire a test event to your notification plugin (do not override)
  NotificationPlugin.fireTestEvent = (config, callback) ->
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
    return


  # Configuration validation methods (do not override)
  NotificationPlugin.validateConfig = (config, pluginConfigFile) ->
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
        return

    return

  NotificationPlugin
)()
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
    return
