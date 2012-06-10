require("sugar");

//
// The base Bugsnag NotificationPlugin class
// Extend this class to create your own Bugsnag notification plugins:
//
//   NotificationPlugin = require "../../notification-plugin.js"
//   class MyPlugin extends NotificationPlugin
//     @receiveEvent = (config, reason, project, error) ->
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
  NotificationPlugin.receiveEvent = function (config, reason, project, error) {
    throw new Error("Plugins must override receiveEvent");
  };


  // Build a short message from this event
  NotificationPlugin.shortMessage = function (reason, projectName, error) {
    return "[" + reason + " on " + projectName + "] " + error.exceptionClass + ": " + (error.message.substr(0, 10));
  };


  // Utility methods for http requests
  var request = require("superagent");
  NotificationPlugin.httpGet = function (url, params, callback) {
    return request.get(url).send(params).end(callback);
  };

  NotificationPlugin.httpPost = function (url, params, callback) {
    return request.post(url).send(params).type("form").end(callback);
  };

  NotificationPlugin.httpPostJson = function (url, obj, callback) {
    return request.post(url).send(obj).end(callback);
  };


  // Fire a test event to your notification plugin (do not override)
  NotificationPlugin.fireTestEvent = function (config) {
    var error, projectName, reason;
    reason = "First exception";
    projectName = "Example";
    error = {
      "exceptionClass": "RuntimeError",
      "message": "Something really bad happened",
      "context": "home#example",
      "appVersion": "1.0.0",
      "releaseStage": "production",
      "firstStacktraceLine": "app/example_controller.rb:87 - example",
      "totalOccurrences": 5,
      "usersAffected": 5,
      "contextsAffected": 1,
      "firstReceived": new Date(),
      "eventUrl": "http://www.bugsnag.com/blah"
    };
    return this.receiveEvent(config, reason, projectName, error);
  };


  // Configuration validation methods (do not override)
  var configError = function (message) {
    throw new Error("ConfigurationError: " + message);
  };

  NotificationPlugin.validateConfig = function (config, pluginConfigFile) {
    var fs = require("fs");
    var pluginConfig = JSON.parse(fs.readFileSync(pluginConfigFile, "ascii"));
    pluginConfig.options.each(function (option) {
      var configValue = config[option.name];

      // Validate all non-optional config options are present
      if (!(configValue || option.optional)) {
        configError("Missing '" + option.name + "'");
      }

      // Validate fields with allowed values
      if (configValue && option.allowedValues && option.allowedValues.none(configValue)) {
        configError("Invalid value for '" + option.name + "'");
      }
    });
  };


  return NotificationPlugin;
})();
module.exports = NotificationPlugin;



// If running plugins from the command line, allow them to fire test events
if (module.parent && module.parent.parent === null) {
  var path = require("path");
  var argv = require("optimist").argv;

  var flags = Object.keys(argv).exclude("_", "$0");
  var config = {};
  flags.each(function (flag) {
    config[flag] = argv[flag];
  });

  NotificationPlugin.validateConfig(config, path.dirname(module.parent.filename) + "/config.json");

  var plugin = require(module.parent.filename);
  plugin.fireTestEvent(config);
}