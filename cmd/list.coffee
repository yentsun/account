module.exports = (seneca, options) ->

  cmd_list = (args, respond) ->

    skip = args.skip
    limit = args.limit

    seneca.log.debug 'getting list of accounts'

    account_records = seneca.make options.zone, options.base, 'account'
    account_records.list$ {skip$:skip, limit$:limit}, (error, accounts) ->
      if error
        seneca.log.error 'error while loading accounts:', error.message
        respond error, null
      else
        respond null, accounts

  cmd_list