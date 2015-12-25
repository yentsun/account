jwt = require 'jsonwebtoken'

login = (options) ->
    seneca = @
    seneca.add 'plugin:login', (params, respond) ->
            account_id = params.account_id
            password = params.password

            seneca.act 'plugin:authenticate',
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

module.exports = login
