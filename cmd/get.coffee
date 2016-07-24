module.exports = (seneca, options) ->

    cmd_get = (args, respond) ->
        id = args.account_id
        account_records = seneca.make options.zone, options.base, 'account'
        account_records.load$ id, (error, account) ->
            if error
                seneca.log.error 'error while loading account:', error.message
                respond error, null
            else
                respond null, account

    cmd_get
