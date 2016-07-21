async = require 'async'

module.exports = (seneca, options) ->

    acl = options.acl

    cmd_authorize = (args, respond) ->

        resource = args.resource
        action = args.action
        token = args.token
        accountId = args.accountId or 'anonymous'
        aud = args.aud or 'web'

        response =
            authorized: false

        async.waterfall [

            (decodingDone) ->
                if token
                    # verify and read token payload
                    seneca.act 'role:account,cmd:verify', {token: token}, (error, res) ->
                        # if error seneca will fail with fatal
                        payload = res.decoded
                        if !payload or !payload.id or !payload.aud
                            seneca.log.error 'decoding failed'
                            return respond null, response
                        return decodingDone null, payload
                else
                    return decodingDone null, null

            , (payload, callback) ->
                if payload and payload.id and payload.aud
                    seneca.log.debug 'using decoded account id...'
                    accountId = payload.id
                    aud = payload.aud
                if accountId != 'anonymous'
                    seneca.act 'role:account,cmd:get', {account_id: accountId}, (error, account) ->
                        if account
                            seneca.log.debug 'got user from storage'
                            # return identified user status
                            return callback null, "#{aud}:#{account.status}"
                        else
                            seneca.log.warn 'failed to get user from storage'
                            return callback null, "#{aud}:#{accountId}"
                else
                    # just return `anonymous` status
                    return callback null, "#{aud}:anonymous"

        ], (error, status) ->
            seneca.log.debug "checking access for user #{accountId}:", status, resource, action
            acl.addUserRoles accountId, [status], (error) ->
                if error
                    seneca.log.error 'attaching role to account failed:', error.message
                    return respond error, null
                acl.isAllowed accountId, resource, action, (error, authorized) ->
                    if error
                        seneca.log.error 'access check failed', error
                        return respond error, null
                    response.authorized = authorized
                    return respond null, response

    cmd_authorize
