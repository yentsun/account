jwt = require 'jsonwebtoken'

module.exports = (seneca, options) ->

    cmd_issue_token = (args, respond) ->
        args.id = args.account_id
        delete args.account_id
        args.reason = args.reason or 'auth'
        res = {}
        secret = options.secret
        res.token = jwt.sign args,
            secret,
            noTimestamp: options.jwtNoTimestamp
        respond null, res

    cmd_issue_token
