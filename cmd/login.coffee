jwt = require 'jsonwebtoken'

module.exports = (seneca, options) ->

    cmd_login = (params, respond) ->
        account_id = params.email
        res = {}
        secret = options.token_secret
        res.token = jwt.sign {id: account_id},
            secret,
            noTimestamp: options.jwtNoTimestamp
        respond null, res

    cmd_login
