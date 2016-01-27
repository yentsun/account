module.exports = (seneca, options) ->

    cmd_get = (args, respond) ->
        id = args.account_id
        account_records = seneca.make 'account'
        account_records.load$ id, (error, account) ->
            if error
                seneca.log.error 'error while loading account', email, error.message
                respond null, null
            else
                respond null, account

    cmd_get
