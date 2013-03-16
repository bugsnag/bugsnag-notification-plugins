require("sugar");

//
// The base Bugsnag NotificationPlugin class
// Extend this class to create your own Bugsnag notification plugins:
//
//   NotificationPlugin = require "../../notification-plugin.js"
//   class MyPlugin extends NotificationPlugin
//     @receiveEvent = (config, event) ->
//       ...
//   module.exports = MyPlugin
//
// All notification plugins must override the receiveEvent function to perform
// the notification. This method is fired when a new event is triggered.
//
// See https://github.com/bugsnag/bugsnag-notification-plugins/ for full docs
//

var NotificationPlugin = (function () {
  function NotificationPlugin() {}

  // Fired when a new event is triggered for notification
  // Plugins MUST override this method
  NotificationPlugin.receiveEvent = function (config, event, callback) {
    throw new Error("Plugins must override receiveEvent");
  };


  // Utility methods for generating notification content
  NotificationPlugin.stacktraceLineString = function (stacktraceLine) {
    return stacktraceLine.file + ":" + stacktraceLine.lineNumber + " - " + stacktraceLine.method
  };

  NotificationPlugin.firstStacktraceLine = function (stacktrace) {
    for(var i=0; i<stacktrace.length; i++) {
      var line = stacktrace[i];
      if(line.inProject) {
        return this.stacktraceLineString(line);
      }
    }

    return this.stacktraceLineString(stacktrace[0]);
  };


  // Utility methods for http requests
  NotificationPlugin.request = require("superagent");


  // Fire a test event to your notification plugin (do not override)
  NotificationPlugin.fireTestEvent = function (config, callback) {
    var event = {
      error: {
        exceptionClass: "ExampleException",
        message: "Something really bad happened",
        context: "home#example",
        appVersion: "1.0.0",
        releaseStage: "production",
        occurrences: 42,
        firstReceived: new Date(),
        usersAffected: 20,
        url: "http://bugsnag.com/errors/example/events/example",
        stacktrace: [{
          file: "app/controllers/home_controller.rb",
          lineNumber: 123,
          method: "example",
          inProject: true
        }]
      },
      project: {
        name: "Example.com",
        url: "http://bugsnag.com/projects/example"
      },
      trigger: {
        type: "firstException",
        message: "New exception"
      }
    };

    this.receiveEvent(config, event, callback);
  };


  // Configuration validation methods (do not override)
  NotificationPlugin.validateConfig = function (config, pluginConfigFile) {
    var fs = require("fs");
    var pluginConfig = JSON.parse(fs.readFileSync(pluginConfigFile, "ascii"));
    if(pluginConfig.fields) {
      pluginConfig.fields.each(function (option) {
        var configValue = config[option.name];

        // Validate all non-optional config fields are present
        if (!(configValue !== undefined || option.optional || (option.type == "boolean" && option.defaultValue !== undefined))) {
          throw new Error("ConfigurationError: Required configuration option '" + option.name + "' is missing");
        }

        // Validate fields with allowed values
        if (configValue !== undefined && option.allowedValues && option.allowedValues.none(configValue)) {
          throw new Error("ConfigurationError: Invalid value for '" + option.name + "'");
        }

        // Fill in default values
        if(configValue == undefined && option.defaultValue !== undefined) {
          config[option.name] = option.defaultValue;
        }
      });
    }
  };


  return NotificationPlugin;
})();
module.exports = NotificationPlugin;



// If running plugins from the command line, allow them to fire test events
if (module.parent && module.parent.parent === null) {
  var path = require("path");
  var argv = require("optimist").argv;

  // Parse command line flags
  var flags = Object.keys(argv).exclude("_", "$0");
  var config = {};
  flags.each(function (flag) {
    if(argv[flag] != null && argv[flag] != "") {
      config[flag] = argv[flag];
    }
  });

  // Validate configuration
  try {
    NotificationPlugin.validateConfig(config, path.dirname(module.parent.filename) + "/config.json");
  } catch (err) {
    return console.error(err.message);
  }

  // Fire a test event
  var plugin = require(module.parent.filename);
  plugin.fireTestEvent(config, function (err, data) {
    if(err) {
      console.error("Error firing notification\n", err.stack);
    } else {
      console.log("Fired test event successfully\n", data);
    }
  });
}