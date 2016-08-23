bcrypt = require 'bcryptjs'
_ = require 'lodash'

module.exports = (seneca, options) ->

    cmd_authenticate = (params, respond) ->
        email = params.email.toLowerCase()
        password = params.password

        if email and password
            # get the account
            seneca.act 'role:account,cmd:identify', {email: email}, (error, account) ->
                if account
                    seneca.log.debug 'account identified', account.id
                    bcrypt.compare password, account.hash, (error, passed) ->
                        if error
                            seneca.log.error 'password check failed:', error.message
                            respond null, null
                        else
                            seneca.log.debug 'password check returned', passed
                            if passed
                                respond null, account
                            else
                                respond null, null
                else
                    seneca.log.debug 'authentication failed, unidentified account', email
                    respond null, null
        else
            seneca.log.error 'missing account_id or password', email, password
            respond null, null

    cmd_authenticate
