jwt = require 'jsonwebtoken'
_ = require 'lodash'

module.exports = (seneca, options) ->

    cmd_issue_token = (args, respond) ->
        account_id = args.account_id
        custom_payload = args.payload
        aud = args.aud or 'web'
        payload =
            id: account_id
            aud: aud
        res = {}
        secret = options.secret
        _.merge payload, custom_payload
        seneca.log.debug 'signing payload:', payload
        res.token = jwt.sign payload,
            secret,
            noTimestamp: options.jwtNoTimestamp
        respond null, res

    cmd_issue_token
