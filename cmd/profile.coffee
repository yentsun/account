
profile = (options) ->
    seneca = @
    plugin = 'profile'

    # GET
    seneca.add "plugin:#{plugin},action:get", (params, respond) ->
        account_id = params.account_id

        storage = seneca.make plugin
        storage.load$ account_id, (error, profile) ->
            respond error, profile

    # UPDATE
    seneca.add "plugin:#{plugin},action:update", (params, respond) ->
        # get the token from normal args or Express header
        # token = args.token or args.req$.headers.authorization.replace 'Bearer ', ''
        data = params.data
        account_id = params.account_id

        seneca.act "plugin:#{plugin},action:get", {account_id: account_id}, (error, profile) ->
            if !profile
                seneca.log.debug 'failed to load existing profile for ', account_id
                seneca.log.debug 'creating new profile record for ', account_id
                data.id = account_id
                seneca.make plugin
                .data$ data
                .save$ (error, profile) ->
                    seneca.log.debug 'new profile saved for ', account_id
                    respond error, profile
            else
                profile.data$ data
                .save$ (error, profile) ->
                    seneca.log.debug 'profile updated for ', account_id
                    respond error, profile

module.exports = profile
