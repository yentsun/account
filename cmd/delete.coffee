module.exports = (seneca, options) ->

    cmd_delete = (msg, respond) ->
        id = msg.email
        account_records = seneca.make 'account'
        account_records.remove$ id, (error) ->
            if error
                seneca.log.error 'error while deleting account', id, error.message
                seneca.act 'role:error,cmd:register',
                    from: 'account.delete.entity.remove$',
                    message: error.message
                    args:
                        id: id
            respond error, null

    cmd_delete
