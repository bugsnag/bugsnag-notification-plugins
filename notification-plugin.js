var sugar = require("sugar");
var request = require("superagent");
var fs = require("fs");
var path = require("path");

var NotificationPlugin = (function() {
  function NotificationPlugin() {}

  NotificationPlugin.shortMessage = function(reason, projectName, error) {
    return "[" + reason + " on " + projectName + "] " + error.exceptionClass + ": " + (error.message.substr(0, 10));
  };

  NotificationPlugin.httpGet = function(url, params, callback) {
    return request.get(url).send(params).end(callback);
  };

  NotificationPlugin.httpPost = function(url, params, callback) {
    return request.post(url).send(params).type("form").end(callback);
  };

  NotificationPlugin.httpPostJson = function(url, obj, callback) {
    return request.post(url).send(obj).end(callback);
  };

  NotificationPlugin.fireTestEvent = function(config) {
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
    return NotificationPlugin.receiveEvent(config, reason, projectName, error);
  };

  NotificationPlugin.validateConfig = function(config, pluginConfigFile) {
    var pluginConfig = JSON.parse(fs.readFileSync(pluginConfigFile, "ascii"));
    pluginConfig.options.each(function (option) {
      var configValue = config[option.name];

      // Validate all non-optional config options are present
      if (!(configValue || option.optional)) {
        NotificationPlugin.configError("Missing '" + option.name + "'");
      }

      // Validate fields with allowed values
      if (configValue && option.allowedValues && option.allowedValues.none(configValue)) {
        NotificationPlugin.configError("Invalid value for '" + option.name + "'");
      }
    });
  };

  NotificationPlugin.configError = function(message) {
    throw new Error("ConfigurationError: " + message);
  };

  NotificationPlugin.receiveEvent = function(reason, projectName, error) {
    throw new Error("Plugins must override receiveEvent");
  };

  return NotificationPlugin;
})();
module.exports = NotificationPlugin;


// If running plugins from the command line, allow them to fire test events
if (module.parent && module.parent.parent === null) {
  var argv = require("optimist").argv;
  var flags = Object.keys(argv).exclude("_", "$0");
  if (flags.length > 0) {
    var config = {};
    flags.each(function (flag) {
      config[flag] = argv[flag];
    });

    NotificationPlugin.validateConfig(config, "" + (path.dirname(module.parent.filename)) + "/config.json");
    var plugin = require(module.parent.filename);
    plugin.fireTestEvent(config);
  }
}