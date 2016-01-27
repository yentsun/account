module.exports = (seneca, options) ->

    acl = options.acl

    cmd_authorize = (args, respond) ->
        resource = args.resource
        action = args.action
        token = args.token
        account = seneca.pin
            role: 'account'
            cmd: '*'
        response =
            authorized: false

        # verify and read token payload
        account.verify {token: token}, (error, res) ->
            if error or !res.decoded
                return respond null, response

            account_id = res.decoded.id

            if !account_id
                seneca.log.error 'failed to decode id'
                return respond null, response

            account.get {account_id: account_id}, (error, account) ->
                if account
                    seneca.log.debug 'checking access', account.id, resource, action

                    acl.addUserRoles account_id, [account.status], (error) ->
                        if error
                            seneca.log.error 'adding role to account failed:', error.message
                            return respond error, null

                        acl.isAllowed account_id, resource, action, (error, res) ->
                            if error
                                seneca.log.error 'access check failed', error
                                respond null, response
                            else
                                response.authorized = res
                                respond null, response
                else
                    seneca.log.debug 'authorization failed, unidentified account', account_id
                    respond null, response

    cmd_authorize
