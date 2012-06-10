Bugsnag Notification Plugins
============================

Bugsnag.com can notify you when errors happen in your applications.
We've created a plugin architecture so you can contribute notification 
plugins for services you use.


Steps to contributing
---------------------

- Fork the project
- Create a new folder in `/plugins/` for your plugin
- Create the plugin file as `index.js` or `index.coffee`, see below for instructions
- Create a `config.json` file describing the usage and configurable settings for your plugin
- Add a 50x50 `icon.png` file representing your plugin
- If necessary, add any node module dependencies to the base `package.json` file
- Send a pull request from your fork to bugsnag/bugsnag-notification-plugins


Writing your plugin
-------------------

Notification plugins should be written in JavaScript or CoffeeScript and are 
executed in a queue using our internal node.js application.

Plugins should extend the base `NotificationPlugin` class defined in
`notification-plugin.js` and override the `receiveEvent` function to perform 
the notification. This method is fired when a new event is triggered.

It is easiest to write plugins using CoffeeScript, for example:

```coffeescript
NotificationPlugin = require "../../notification-plugin.js"
class MyPlugin extends NotificationPlugin
  @receiveEvent = (config, reason, project, error) ->
    # Do the hard work here

module.exports = MyPlugin
```

If you prefer to write your plugin with plain old JavaScript, this is also 
possible:

```javascript
var util = require("util");
var NotificationPlugin = require("../../notification-plugin.js")

function MyPlugin() {}
util.inherits(MyPlugin, NotificationPlugin);
MyPlugin.receiveEvent = function (config, reason, project, error) {
  // Do the hard work here
};

module.exports = MyPlugin;
```


HTTP helper methods
-------------------

Since most notification plugins will use http for communication to external 
services, we've provided some helper functions to make basic http request:

```javascript
// Perform a HTTP GET request
NotificationPlugin.httpGet(url, params, callback)

// Perform a HTTP POST request
NotificationPlugin.httpPost(url, params, callback)

// Perform a HTTP POST request with a JSON body
NotificationPlugin.httpPostJson(url, params, callback)
```


Testing your plugin
-------------------

By extending the `NotificationPlugin` class, you'll be able to test your 
plugin directly on the command line as follows:

    > node index.js --option=value --anotherOption=something

Command line options represent the customizable per-project settings as
defined in your `config.json` file.


config.json format
------------------

For a quick example of the `config.json` file format, take a look at the
[Hipchat plugin config.json](https://raw.github.com/bugsnag/bugsnag-notification-plugins/refactor/plugins/hipchat/config.json).

Your plugin's `config.json` file describes to users how to use and configure
your plugin from their Bugsnag dashboard. The file must be a valid JSON file
and contain the following top-level keys:

-   **name**

    The name of your plugin, eg. "Hipchat"

-   **description**

    A simple description of the action that will be performed, 
    eg. "Post to a Hipchat chatroom"

-   **instructions**

    Any further instructions to present to the user (optional)

-   **fields**

    An array of fields to present to the user on the Bugsnag.com dashboard. 
    Each field should contain the following keys:

    -   **name**

        A simple camelcase name for this field, eg. "authToken"

    -   **label**

        The label to display to the user for this field, eg. "Auth Token"

    -   **description**

        A full description or hint for this field, eg "Your Hipchat auth token
        from the dashboard on hipchat.com" (optional)

    -   **type**

        The data type of this field, either `string` or `boolean`
        (optional, defaults to `string`)

    -   **allowedValues**

        An array of allowed values for this field. When this is set, this 
        option will be presented in a dropdown list (optional).

    -   **defaultValue**

        A default value for this field.