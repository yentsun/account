module.exports = (seneca, options) ->

    cmd_identify = (args, respond) ->
        email = args.email
        account_records = seneca.make options.zone, options.base, 'account'
        account_records.list$ {email: email}, (error, accounts) ->
            if error
                seneca.log.error 'error while loading account', email, error.message
                respond null, null
            else
                respond null, accounts[0]

    cmd_identify
