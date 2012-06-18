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
MyPlugin.receiveEvent = function (config, event) {
  // Do the hard work here
};

module.exports = MyPlugin;
```


Event Format
------------
As well as being passed in the users configuration for your notification, you are passed
an event object, which tells you what the user needs to be notified about.

```javascript
event: {
    // Contains information about the project which has had an event
    project: {
        // The project name
        name: "Project Name",
        
        // The url for the Bugsnag dashboard of the project
        url: "https://bugsnag.com/projects/project-name"
    },
    // The reason the user is being notified by the notifier
    trigger: {
        // The identifier for the reason for notification
        type: "firstException",
        
        // The human readable form of the trigger. This can be used to start a sentance.
        message: "New exception"
    },
    // The error that caused the notification (optional). Will not be present if the project has hit the rate limit.
    error: {
        // The class of exception that caused the error
        exceptionClass: "NullPointerException",
        
        // The message that came with the exception. This may not be present if the exception didnt generate one.
        message: "Null cannot be dereferenced",
        
        // The context that was active in the application when the error occurred. This could be which screen
        // the user was using at the time, for example.
        context: "BugsnagMainActivity",
        
        // The application version
        appVersion: "1.2.3",
        
        // The release stage, will most often be production, or development.
        releaseStage: "production",
        
        // The number of times this exception has occured (including this one)
        occurrences: 1,
        
        // When was the error first received. Will be a Date object.
        firstReceived: new Date(),
        
        // How many users have been affected. Could be 0 if there was no user associated with the error.
        usersAffected: 1,
        
        // The stack trace for this error. An array of stack frames.
        stacktrace: [{
            // The file that this stack frame was in.
            file: "BugsnagMainActivity.java",
            
            // The line number of the stack frame, within the file.
            lineNumber: 123,
            
            // The method that was being executed.
            method: "onCreate",
            
            // Indicates that this stack fram was within the project. If the key is not present, 
            // it is assumed to be false.
            inProject: true
        },...
        ]
    }
}
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

-   **supportedTriggers**

    We trigger notifications when certain events occur in bugsnag (see the 
    Event Format) documentation above. To signal which triggers your plugin
    understands, set this to an array of trigger strings.
    eg. ["exception", "firstException"].

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