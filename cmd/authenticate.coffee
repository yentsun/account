bcrypt = require 'bcryptjs'
_ = require 'lodash'

module.exports = (seneca, options) ->

    cmd_authenticate = (params, respond) ->
        email = params.email.toLowerCase()
        password = params.password
        response =
            authenticated: false

        if email and password
            # get the account
            seneca.act 'role:account,cmd:identify', {email: email}, (error, account) ->
                if account
                    seneca.log.debug 'account identified', account.id
                    bcrypt.compare password, account.hash, (error, passed) ->
                        if error
                            seneca.log.error 'password check failed:', error.message
                            respond null, response
                        else
                            seneca.log.debug 'password check returned', passed
                            response.authenticated = passed
                            if passed
                                _.merge response, account
                            respond null, response
                else
                    seneca.log.debug 'authentication failed, unidentified account', email
                    response.identified = false # TODO is this really needed?
                    respond null, response
        else
            seneca.log.error 'missing account_id or password', email, password
            respond null, response

    cmd_authenticate
