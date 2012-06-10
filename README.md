Plugin Implementation
=====================

- JavaScript or CoffeeScript
- Override `receiveEvent`
- Only add module dependencies to package.json if they are absolutely necessary
- Make a pull request


Plugin File Structure
=====================

A Bugsnag notification plugin should contain the following files:

-   `config.json`

    A valid json file describing the plugin and any configurable settings 
    the plugin may have. See below for details.

-   `index.js` or `index.coffee`

    The main code for the plugin. This should be a javascript class which
    inherits from the base `NotificationPlugin` class. See below for details.

-   `icon.png`
    
    A 32x32 png image representing the plugin.


Plugin Class
============
- JavaScript use `Object.merge` from sugarjs
- CoffeeScript use `extends`
- Override `receiveEvent`


Format of config.json
=====================

TODO