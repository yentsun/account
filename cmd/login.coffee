jwt = require 'jsonwebtoken'

module.exports = (seneca, options) ->

    cmd_login = (params, respond) ->
            account_id = params.account_id
            password = params.password

            seneca.act 'role:account,cmd:authenticate',
                account_id: account_id
                password: password
                , (error, res) ->
                    if res and res.authenticated
                        # issue a token
                        secret = options.secret
                        res.token = jwt.sign {id: account_id},
                            secret,
                            noTimestamp: options.jwtNoTimestamp
                        respond null, res
                    else
                        respond null, res

    cmd_login
