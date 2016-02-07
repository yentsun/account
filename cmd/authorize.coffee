async = require 'async'

module.exports = (seneca, options) ->

    acl = options.acl

    cmd_authorize = (args, respond) ->

        resource = args.resource
        action = args.action
        token = args.token
        accountId = args.accountId or 'anonymous'

        account = seneca.pin
            role: 'account'
            cmd: '*'
        response =
            authorized: false

        async.waterfall [

            (callback) ->
                if token
                    # verify and read token payload
                    account.verify {token: token}, (error, res) ->
                        # if error seneca will fail with fatal
                        if !res.decoded or !res.decoded.id
                            seneca.log.error 'failed to decode id'
                            return respond null, response
                        return callback null, res.decoded.id
                else
                    return callback null, null

            , (decodedAccouintId, callback) ->
                if decodedAccouintId
                    seneca.log.debug 'using decoded account id...'
                    accountId = decodedAccouintId
                if accountId != 'anonymous'
                    account.get {account_id: accountId}, (error, account) ->
                        if account
                            seneca.log.debug 'got user from storage'
                            # return identified user status
                            return callback null, account.status
                        else
                            seneca.log.warn 'failed to get user from storage'
                            return callback null, accountId
                else
                    # just return `anonymous` status
                    return callback null, accountId

        ], (error, status) ->
            seneca.log.debug 'checking access', accountId, resource, action
            acl.addUserRoles accountId, [status], (error) ->
                if error
                    seneca.log.error 'attaching role to account failed:', error.message
                    return respond error, null
                acl.isAllowed accountId, resource, action, (error, authorized) ->
                    if error
                        seneca.log.error 'access check failed', error
                        return respond error, null
                    else
                        response.authorized = authorized
                        return respond null, response

    cmd_authorize
