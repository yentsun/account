async = require 'async'

module.exports = (seneca, options) ->

    cmd_update = (args, respond) ->
        account = seneca.pin
            role: 'account'
            cmd: '*'
        new_status = args.status
        new_password = args.password
        account_id = args.account_id
        account_records = seneca.make 'account'

        # load account
        account_records.load$ account_id, (error, acc) ->
            if error
                seneca.log.error 'error while loading account', account_id, error.message
                return respond error
            else
                seneca.log.debug 'updating account', acc
                async.waterfall [
                    (callback) ->
                        if new_status
                            seneca.log.debug 'updating status...'
                            acc.status = new_status
                        callback null, acc
                    , (acc, callback) ->
                        if new_password
                            seneca.log.debug 'updating password...'
                            account.encrypt {subject: new_password}, (error, res) ->
                                if res.hash
                                    acc.hash = res.hash
                                return callback error, acc
                        else
                            callback null, acc

                ], (error, acc) ->
                    if error
                        seneca.log.error 'account update failed:', error.message
                        return respond error, null
                    acc.save$ (error, saved_acc) ->
                        if error
                            seneca.log.error 'account record update failed:', error.message
                            return respond error, null
                        if saved_acc
                            respond null, saved_acc


    cmd_update
