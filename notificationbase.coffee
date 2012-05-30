exports.createNotification = (notificationRow, triggerRow, accountHandle, projectHandle, event, error) ->
    notificationRequire = require(require('path').join(__dirname,notificationRow.notificationType))
    return new notificationRequire.Notification notificationRow,
                                                triggerRow,
                                                accountHandle,
                                                projectHandle,
                                                event,
                                                error

class exports.NotificationBase
    dbConnection: null
    
    # Constructor bla bla
    constructor: (@notificationRow, triggerRow, @accountHandle, @projectHandle, @event, @error) ->
        @target_type = triggerRow.triggerOwner_type
        @target_id = triggerRow.triggerOwner_id
        @trigger_type = triggerRow.type
        @configuration = @notificationRow.configuration
        @emails = null
        @target = null
        
    # Implemented by the Notification class
    executeNotification: (callback) =>
        return

    # Execute the notification - merely wraps it in a try catch
    run: (callback) =>
        try
            @executeNotification(callback)
        catch error
            callback "Error from notification #{@notificationRow.notificationType}! Contents: #{error}"
    
    # Access the mongodb  
    db: ->
        return exports.NotificationBase::dbConnection
    
    errorUrl: (callback) =>
        @projectHandle.fetch (err, project) =>
            return callback(err, null) if err?
            return callback(null, "http://www.bugsnag.com/projects/#{project.slug}/errors/#{@error._id}")
         
    # Fetches the target of the notification. callback(err, target)   
    fetchTarget: (callback) =>
        if @target?
            return process.nextTick () =>
                callback null, @target
        switch @target_type
            when "User"
                @db.collection("users").find({ _id:@target_id }).toArray (err,results) =>
                    if err or not (results? and results.length == 1)
                        return callback( "Error when looking for user as trigger owner! Contents #{err}", null)
                    @target = results[0]
                    return callback(null, @target)
            when "Project"
                @projectHandle.fetch (err, project) =>
                    return callback(err, null) if err?
                    @target = project
                    return callback(null, @target)
            else
                @target = null
                return callback("Unknown notification target type: #{@target_type}", null)

    # Fetch the email addresses associated with the notification target.
    # callback(err, [emails])
    emailAddresses: (callback) =>
        if @emails?
            return process.nextTick () =>
                callback null, @emails
        switch @target_type
            when "Project"
                @fetchTarget (err, target) =>
                    return callback(err, null) if err?
                    @db.collection("users").find( { $or: [{_id: { $in:target.user_ids }}, { account_admin: true, account_id: target.account_id} ], invitation_token: null}, { fields: ["email"] }).toArray (err, results) =>
                        if err
                            return callback("Error when looking project email addresses! Contents: #{err}", null)
                        else
                            @emails = (user.email for user in results)
                            return callback(null, @emails)
            when "User"
                @fetchTarget (err, target) =>
                    return callback(err, null) if err?
                    @emails = [@target.email]
                    return callback(null, @emails)
            else
                return callback("Unknown notification target type: #{@target_type}", [])