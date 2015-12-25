# nothing more than getting an account from storage

module.exports = () ->
    seneca = @
    seneca.add 'plugin:identify', (params, respond) ->
        id = params.account_id
        account_records = seneca.make 'account'
        account_records.load$ id, (error, account) ->
            if error
                seneca.log.error 'error while loading account', id, error.message
                respond null, null
            else
                respond null, account

    'identify'
