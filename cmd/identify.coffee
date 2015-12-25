module.exports = (seneca, options) ->

    cmd_identify = (msg, respond) ->
        id = msg.account_id
        account_records = seneca.make 'account'
        account_records.load$ id, (error, account) ->
            if error
                seneca.log.error 'error while loading account', id, error.message
                respond null, null
            else
                respond null, account

    cmd_identify
