module.exports = (seneca, options) ->

    cmd_delete = (msg, respond) ->
        id = msg.account_id
        account_records = seneca.make options.zone, options.base, 'account'
        account_records.remove$ id, (error) ->
            if error
                seneca.log.error 'error while deleting account', id, error.message
            respond error, null

    cmd_delete
