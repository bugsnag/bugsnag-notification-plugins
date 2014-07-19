require("sugar");
fs = require("fs");
Handlebars = require("handlebars");

Handlebars.registerHelper("eachSummaryFrame", function (stack, options) {
  return NotificationPlugin.getSummaryStacktrace(stack).map(function (line) {
    return options.fn(line);
  }).join('');
});

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

  // Load templates
  NotificationPlugin.markdownTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.md.hbs", "utf8"));
  NotificationPlugin.htmlTemplate = Handlebars.compile(fs.readFileSync(__dirname + "/templates/error.html.hbs", "utf8"));

  // Fired when a new event is triggered for notification
  // Plugins MUST override this method
  NotificationPlugin.receiveEvent = function (config, event, callback) {
    throw new Error("Plugins must override receiveEvent");
  };


  // Utility methods for generating notification content
  NotificationPlugin.stacktraceLineString = function (stacktraceLine) {
    return stacktraceLine.file + ":" + stacktraceLine.lineNumber + " - " + stacktraceLine.method
  };

  NotificationPlugin.basicStacktrace = function (stacktrace) {
    return this.getSummaryStacktrace(stacktrace).map(function (line) {
      return this.stacktraceLineString(line);
    }, this).join("\n");
  };

  // Returns the first line of a stacktrace (formatted)
  NotificationPlugin.firstStacktraceLine = function (stacktrace) {
    return this.stacktraceLineString(this.getSummaryStacktrace(stacktrace)[0]);
  };

  // Utility to determine whether a stacktrace line is `inProject`
  NotificationPlugin.inProjectStacktraceLine = function (line) {
    return line != null && "inProject" in line && line.inProject;
  };

  // Utility for getting all the stacktrace lines that are `inProject`
  NotificationPlugin.getSummaryStacktrace = function (stacktrace) {
    var filtered;

    // If there are no 'inProject' stacktrace lines
    if ( ! (filtered = stacktrace.filter(this.inProjectStacktraceLine)).length) {
      filtered = stacktrace.slice(0, 3);
    }

    return filtered;
  };

  NotificationPlugin.title = function (event) {
    return event.error.exceptionClass + " in " + event.error.context;
  };

  NotificationPlugin.markdownBody = function (event) {
    return this.markdownTemplate(event);
  };

  NotificationPlugin.htmlBody = function (event) {
    return this.htmlTemplate(event);
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
        }, {
          file: "app/controllers/other_controller.rb",
          lineNumber: 12,
          method: "broken",
          inProject: true
        }, {
          file: "gems/junk/junkfile.rb",
          lineNumber: 999,
          method: "something",
          inProject: false
        }, {
          file: "lib/important/magic.rb",
          lineNumber: 4,
          method: "load_something",
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
      console.error("Error firing notification\n", err);
    } else {
      console.log("Fired test event successfully\n", data);
    }
  });
}