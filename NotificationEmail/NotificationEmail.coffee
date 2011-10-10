nodemailer = require('nodemailer')
mustache = require('mustache')
fs = require('fs')

try
    template = fs.readFileSync(require('path').join(__dirname, "htmlemail.mustache"), "utf-8")
catch err
    console.log("NotificationEmail: error reading template: " + err)

#TODO:SM We should make it so that people can turn this off from the email itself.
exports.executeNotification = (account, project, triggerText, event, options) ->
    nodemailer.sendmail = true
    
    variables = {
      projectName: project.name,
      projectSlug: project.slug,
      errorId: event.errorHash,
      appVersion: event.appEnvironment.appVersion,
      eventMessage: event.causes[0].errorClass + ": " + event.causes[0].message,
      eventLocation: event.causes[0].stacktrace[0].file + " at " + event.causes[0].stacktrace[0].lineNumber,
      eventTrace: event.causes[0].stacktrace
    }
    
    unless template?
        try
            template = fs.readFileSync(require('path').join(__dirname, "htmlemail.mustache"), "utf-8")
        catch err
            console.log("NotificationEmail: error reading template: " + err)
            console.log("NotificationEmail: cancelling email to address " + options.email)
            return

    html = mustache.to_html(template, variables);
    
    console.log("Firing an email for user at address " + options.email)
    nodemailer.send_mail {
        to : options.email,
        subject : triggerText + " on " + project.name,
        sender: 'Bugsnag <noreply@bugsnag.com>',
        html: html,
        body: html
    }, (err, result) ->
        if(err)
            console.log("NotificationEmail: error sending email " + err)