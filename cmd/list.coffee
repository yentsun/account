exports.cmd_list = (seneca, options) ->
    
    cmd_list = (args, respond) ->
        skip = args.skip
        limit = args.limit
        
        seneca.log.debug 'getting list of accounts'
        
        account_records = seneca.make options.zone, options.base, 'account'
        account_records.list$ {skip$: skip, limit$: limit}, (error, accounts) ->
            if error
                seneca.log.error 'error while loading accounts:', error.message
                respond error, null
            else
                respond null, accounts
    
    cmd_list

exports.cmd_count = (seneca, options) ->
    
    cmd_count = (args, respond) ->
        
        seneca.log.debug 'getting amount of accounts'
        
        account_records = seneca.make options.zone, options.base, 'account'
        account_records.list$ (error, accounts) ->
            if error
                seneca.log.error 'error while loading accounts:', error.message
                respond error, null
            else
                respond null, {number: accounts.length}
    
    cmd_count