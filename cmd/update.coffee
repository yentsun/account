async = require 'async'

module.exports = (seneca, options) ->

    cmd_update = (args, respond) ->
        
        new_status = args.status
        new_password = args.password
        accountId = args.account_id
        account_records = seneca.make options.zone, options.base, 'account'
        updated = []

        # load account
        account_records.load$ accountId, (error, acc) ->
            if error
                seneca.log.error 'error while loading account', accountId, error.message
                return respond error
            if !acc
                message = 'tried to update nonexistent account ' + accountId
                seneca.log.error message
                return respond new Error message
            seneca.log.debug 'updating account', acc.id
            async.waterfall [
                (callback) ->
                    if new_status and (new_status != acc.status)
                        seneca.log.debug 'updating status...'
                        acc.status = new_status
                        updated.push 'status'
                    callback null, acc
                , (acc, callback) ->
                    if new_password
                        seneca.log.debug 'updating password...'
                        updated.push 'password'
                        seneca.act 'role:account,cmd:encrypt', {subject: new_password}, (error, res) ->
                            # if error, seneca will fail with fatal here
                            acc.hash = res.hash
                            return callback error, acc
                    else
                        callback null, acc

            ], (error, acc) ->
                # if error, seneca will fail with earlier
                acc.save$ (error, saved_acc) ->
                    if error
                        seneca.log.error 'account record update failed:', error.message
                        return respond error, null
                    if saved_acc
                        saved_acc.updated = updated
                    respond null, saved_acc


    cmd_update
