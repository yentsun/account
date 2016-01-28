module.exports = (seneca, options) ->

    cmd_update = (args, respond) ->
        account = seneca.pin
            role: 'account'
            cmd: '*'
        new_status = args.status
        account_id = args.account_id
        account_records = seneca.make 'account'

        # load account
        account_records.load$ account_id, (error, acc) ->
            if error
                seneca.log.error 'error while loading account', account_id, error.message
                return respond error
            else
                acc.status = new_status
                # update account record
                acc.save$ (error, saved_acc) ->
                    if error
                        seneca.log.error 'account record update failed:', error.message
                        return respond error, null
                    if saved_acc
                        respond null, saved_acc

    cmd_update
