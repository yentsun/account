async = require 'async'

module.exports = (seneca, options) ->

    acl = options.acl

    cmd_authorize = (args, respond) ->

        resource = args.resource
        action = args.action
        token = args.token
        accountId = args.accountId

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
        ], (error, decodedAccouintId) ->
            if decodedAccouintId
                accountId = decodedAccouintId
            if !accountId
                seneca.log.debug 'accountId not provided'
                return respond null, response
            account.get {account_id: accountId}, (error, account) ->
                if account
                    seneca.log.debug 'checking access', account.id, resource, action
                    acl.addUserRoles accountId, [account.status], (error) ->
                        if error
                            seneca.log.error 'adding role to account failed:', error.message
                            return respond error, null

                        acl.isAllowed accountId, resource, action, (error, res) ->
                            if error
                                seneca.log.error 'access check failed', error
                                respond null, response
                            else
                                response.authorized = res
                                respond null, response
                else
                    seneca.log.debug 'authorization failed, unidentified account', accountId
                    respond null, response

    cmd_authorize
