bcrypt = require 'bcryptjs'

module.exports = (seneca, options) ->

    cmd_authenticate = (params, respond) ->
        account_id = params.account_id
        password = params.password
        response =
            account_id: account_id
            authenticated: false

        if account_id and password
            # get the account
            seneca.act 'role:account,cmd:identify', {account_id: account_id}, (error, account) ->
                if account
                    seneca.log.debug 'account identified', account.id
                    bcrypt.compare password, account.password_hash, (error, passed) ->
                        if error
                            seneca.log.error 'password check failed:', error.message
                            respond null, response
                        else
                            seneca.log.debug 'password check returned', passed
                            response.authenticated = passed
                            respond null, response
                else
                    seneca.log.debug 'authentication failed, unidentified account', account_id
                    response.identified = false
                    respond null, response
        else
            seneca.log.error 'missing account_id or password', account_id, password
            respond null, response

    cmd_authenticate
