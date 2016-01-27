jwt = require 'jsonwebtoken'

module.exports = (seneca, options) ->

    cmd_issue_token = (args, respond) ->
        account_id = args.account_id
        reason = args.reason or 'auth'
        res = {}
        secret = options.secret
        res.reason = reason
        res.token = jwt.sign {id: account_id, reason: reason},
            secret,
            noTimestamp: options.jwtNoTimestamp
        respond null, res

    cmd_issue_token
