require "sugar"
fs = require "fs"
path = require "path"
Handlebars = require "handlebars"
Table = require('cli-table')
argv = require("optimist").argv

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

module.exports = class NotificationPlugin

  # Load templates
  @markdownTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.md.hbs", "utf8"))
  @htmlTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.html.hbs", "utf8"))
  @textTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.text.hbs", "utf8"))

  # Utility methods for http requests
  @request = require "superagent"

  # Fired when a new event is triggered for notification
  # Plugins MUST override this method
  @receiveEvent = (config, event, callback) ->
    throw new Error("Plugins must override receiveEvent")

  # Utility methods for generating notification content
  @stacktraceLineString = (stacktraceLine) ->
    stacktraceLine.file + ":" + stacktraceLine.lineNumber + " - " + stacktraceLine.method

  @basicStacktrace = (stacktrace) ->
    @getSummaryStacktrace(stacktrace).map((line) ->
      @stacktraceLineString line
    , this).join "\n"

  # Returns the first line of a stacktrace (formatted)
  @firstStacktraceLine = (stacktrace) ->
    @stacktraceLineString @getSummaryStacktrace(stacktrace)[0]

  # Utility to determine whether a stacktrace line is `inProject`
  @inProjectStacktraceLine = (line) ->
    line? and "inProject" of line and line.inProject

  # Utility for getting all the stacktrace lines that are `inProject`
  @getSummaryStacktrace = (stacktrace) ->
    filtered = undefined

    # If there are no 'inProject' stacktrace lines
    filtered = stacktrace.slice(0, 3)  unless (filtered = stacktrace.filter(@inProjectStacktraceLine)).length
    filtered

  @title = (event) ->
    event.error.exceptionClass + " in " + event.error.context

  @markdownBody = (event) ->
    @markdownTemplate event

  @htmlBody = (event) ->
    @htmlTemplate event

  @textBody = (event) ->
    @textTemplate event

  # Fire a test event to your notification plugin (do not override)
  @fireTestEvent = (config, callback) ->
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

    if config.reopened
      delete config.reopened
      event.trigger =
        type: "reopened"
        message: "Resolved error re-occurred"

    if config.createdIssue
      info = config.createdIssue.split(",")
      event.error.createdIssue = {}
      event.error.createdIssue[info[0]] = info[1]
      delete config.createdIssue

    @receiveEvent config, event, callback
    return

  # Configuration validation methods (do not override)
  @validateConfig = (config, pluginConfigFile) ->
    pluginConfig = require pluginConfigFile
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

printHelp = (configFile) ->
  table = new Table(
    chars:
      'top': ''
      'top-mid': ''
      'top-left': ''
      'top-right': ''
      'bottom': ''
      'bottom-mid': ''
      'bottom-left': ''
      'bottom-right': ''
      'left': ''
      'left-mid': ''
      'mid': ''
      'mid-mid': ''
      'right': ''
      'right-mid': ''
      'middle': ' '
    style:
      'padding-left': 5
      'padding-right': 0
  )

  configFile.fields.forEach (field) ->
    fieldDesc = "--#{field.name}=#{field.type || "string"}"
    fieldDesc = fieldDesc + " (optional)" if field.optional
    table.push [fieldDesc, field.description]

  table.push ["",""]
  table.push ["--reopened (optional)", "Simulate an error reopening"]
  table.push ["--createdIssue=string,string (optional)", "Simulate created issue metadata key,value"]
  table.push ["--comment (optional)", "Simulate a comment"]
  table.push ["--spike (optional)", "Simulate a project spike"]
  console.log ""
  console.log "Attempting to test the #{path.basename(path.dirname(module.parent.filename))} integration"
  console.log table.toString()

# If running plugins from the command line, allow them to fire test events
if module.parent and module.parent.parent is null
  pluginConfigFile = require(path.dirname(module.parent.filename) + "/config.json")

  # Parse command line flags
  flags = Object.keys(argv).exclude("_", "$0")
  config = {}
  if flags.indexOf("help") != -1
    return printHelp(pluginConfigFile)
  flags.each (flag) ->
    config[flag] = argv[flag] if argv[flag]? and argv[flag] isnt ""

  # Validate configuration
  try
    NotificationPlugin.validateConfig config, path.dirname(module.parent.filename) + "/config.json"
  catch err
    console.error err.message
    printHelp(pluginConfigFile)
    return

  # Fire a test event
  plugin = require(module.parent.filename)
  plugin.fireTestEvent config, (err, data) ->
    if err
      console.error "Error firing notification\n", err
    else
      console.log "Fired test event successfully\n", data
