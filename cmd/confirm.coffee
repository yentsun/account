

module.exports = (seneca, options) ->

    cmd_confirm = (args, respond) ->
        conf_token = args.token
        account = seneca.pin
            role: 'account'
            cmd: '*'

        # verify and read token payload
        account.verify {token: conf_token}, (error, res) ->
            if error or !res.decoded or res.decoded.reason != 'conf'
                return respond null,
                    message: 'token verification error'

            account_records = seneca.make 'account'

            # load account
            account_records.load$ res.decoded.id, (error, acc) ->
                if error
                    seneca.log.error 'error while loading account', decoded.id, error.message
                    respond null, null
                else
                    acc.status = 'confirmed'
                    # update account record
                    acc.save$ (error, saved_acc) ->
                        if error
                            seneca.log.error 'account record update failed:', error.message
                            return respond error, null
                        if saved_acc
                            respond null, saved_acc

    cmd_confirm
