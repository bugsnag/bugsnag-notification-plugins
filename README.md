Bugsnag Notification Plugin Creation Guide
==========================================

Bugsnag.com can notify you when errors happen in your applications.
We've created a plugin architecture so you can contribute notification 
plugins for services you use.

[Bugsnag](http://bugsnag.com) captures errors in real-time from your web, 
mobile and desktop applications, helping you to understand and resolve them 
as fast as possible. [Create a free account](http://bugsnag.com) to start 
capturing exceptions from your applications.


Steps to contributing
---------------------

-   [Fork](https://help.github.com/articles/fork-a-repo) the 
    [bugsnag-notification-plugins project](https://github.com/bugsnag/bugsnag-notification-plugins)
    on GitHub.

-   Create a new folder in `/plugins/` for your plugin

-   Create the plugin file as `index.js` or `index.coffee`, see below for 
    instructions

-   Create a `config.json` file describing the usage and configurable settings
    for your plugin

-   Add a 50x50 `icon.png` file representing your plugin

-   If necessary, add any node module dependencies to the base `package.json` 
    file

-   [Make a pull request](https://help.github.com/articles/using-pull-requests)
    from your fork to [bugsnag/bugsnag-notification-plugins](https://github.com/bugsnag/bugsnag-notification-plugins)


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
  @receiveEvent = (config, event) ->
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


Testing your plugin
-------------------

By extending the `NotificationPlugin` class, you'll be able to test your 
plugin directly on the command line. In your new plugin directory
(`plugins/your-plugin`) run `index.coffee` directly:

    > coffee index.coffee --option=value --anotherOption=something

Command line options represent the customizable per-project settings as
defined in your `config.json` file.

**NOTE:** You should ensure you have run `npm install` in the top level
directory first, to install the dependencies for the project.


Event Format
------------
As well as passing the user's plugin configuration settings, we also pass you
an event object, which tells you the reason we triggered a notification.

```javascript
event: {
    
    // Contains information about the account which has had an event
    account: {
        // The account name
        name: "Account Name",
        
        // The url for the Bugsnag dashboard of the account
        url: "https://bugsnag.com/dashboard/"
    },
    
    // Contains information about the project which has had an event
    project: {
        // The project name
        name: "Project Name",
        
        // The url for the Bugsnag dashboard of the project
        url: "https://bugsnag.com/dashboard/project-name"
    },

    // The reason the user is being notified by the notifier
    trigger: {
        // The identifier for the reason for notification
        type: "firstException",
        
        // The human readable form of the trigger. This can be used to start 
        // a sentance.
        message: "New exception"
    },

    // The error that caused the notification (optional). Will not be present if
    // the project has hit the rate limit.
    error: {
        // The class of exception that caused the error
        exceptionClass: "NullPointerException",
        
        // The message that came with the exception. This may not be present if 
        // the exception didnt generate one.
        message: "Null cannot be dereferenced",
        
        // The context that was active in the application when the error 
        // occurred. This could be which screen
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
        
        // How many users have been affected. Could be 0 if there was no user 
        // associated with the error.
        usersAffected: 1,
        
        // The URL on bugsnag.com with the full details about this error
        url: "https://bugsnag.com/errors/example",
        
        // The stack trace for this error. An array of stack frames.
        stacktrace: [{
            // The file that this stack frame was in.
            file: "BugsnagMainActivity.java",
            
            // The line number of the stack frame, within the file.
            lineNumber: 123,
            
            // The method that was being executed.
            method: "onCreate",
            
            // Indicates that this stack fram was within the project. If the key
            //is not present, it is assumed to be false.
            inProject: true
        }
        ...
        ]
    }
}
```

HTTP request helper
-------------------

Since most notification plugins will use http for communication to external 
services, we've provided a `request` helper function. This function provides
a `superagent` request object, which you can
[read about here](http://visionmedia.github.com/superagent/). Some examples:

```coffeescript
// Perform a HTTP GET request
@request
  .get("http://someurl.com")
  .send(params)
  .end()


// Perform a normal HTTP POST request
@request
  .post("http://someurl.com")
  .send(params)
  .type("form")
  .end()


// Perform a HTTP POST request with a JSON body
@request
  .post("http://someurl.com")
  .send(params)
  .end()
```


config.json format
------------------

Your plugin's `config.json` file describes to users how to use and configure
your plugin from their Bugsnag dashboard. The file must be a valid JSON file
and look similar to the following example:

```javascript
{
    // The name of the plugin.
    "name": "HipChat",
    
    // A simple description of the action that will be performed.
    "description": "Post to a HipChat chatroom",
    
    // We trigger notifications when certain events occur in bugsnag (see the 
    // Event Format documentation above). To signal which triggers your plugin
    // understands, set this to an array of trigger strings. 
    // eg. ["exception", "firstException"]. 
    "supportedTriggers": ["firstException"],
    
    // An array of fields to present to the user on the Bugsnag.com dashboard.
    "fields": [{
        // The name of the field. This is how you will reference the field in 
        // the configuration options that are passed to your notifier when it is
        // run. Should be camelCase.
        "name": "authToken",
        
        // The label to display to the user for this field
        "label": "Auth Token",
        
        // A full description or hint for this field.
        "description": "Your HipChat API auth token",
        
        // The data type of this field, either string, password or boolean 
        // (optional, defaults to string)
        "type": "boolean",
        
        // An array of allowed values for this field. When this is set, this 
        // option will be presented in a dropdown list (optional).
        "allowedValues": ["yellow", "red", "green", "purple", "random"],
        
        // A default value for this field (optional).
        "defaultValue": "yellow"

        // A link to documentation for this field - or a method of obtaining the value (optional)
        // Can also contain other fields by using {fieldName} in the URL. In the following example
        // applicationKey is another configuration option that is required for this URL.
        "link": "https://trello.com/1/authorize?key={applicationKey}&name=Bugsnag"
    }
    ...
    ]
}
```

Reporting Bugs or Feature Requests
----------------------------------

Please report any bugs or feature requests on the github issues page for this
project here:

<https://github.com/bugsnag/bugsnag-notification-plugins/issues>
