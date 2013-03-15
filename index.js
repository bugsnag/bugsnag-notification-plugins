var fs = require("fs");
var path = require("path");

// Allow plugins to be written in coffee-script
require("coffee-script");

// Load and export all plugins
var PLUGINS_PATH = "./plugins";
fs.readdirSync(PLUGINS_PATH).forEach(function (file) {
  var pluginPath = path.join(__dirname, PLUGINS_PATH, file);
  if(fs.statSync(pluginPath).isDirectory()) {
    exports[file] = require(pluginPath);
  }
});