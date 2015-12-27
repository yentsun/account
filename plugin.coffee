authenticate = require './cmd/authenticate'
authorize = require './cmd/authorize'
identify = require './cmd/identify'
login = require './cmd/login'
register = require './cmd/register'
util = require './util'

module.exports = (options) ->
    seneca = @
    role = 'account'

    seneca.add "init:#{role}", (msg, respond) ->
        required = ['starter_role', 'token_secret', 'acl']
        util.check_options options, required
        do respond
    seneca.add "role:#{role},cmd:authenticate", authenticate seneca, options
    seneca.add "role:#{role},cmd:authorize", authorize seneca, options
    seneca.add "role:#{role},cmd:identify", identify seneca, options
    seneca.add "role:#{role},cmd:login", login seneca, options
    seneca.add "role:#{role},cmd:register", register seneca, options
    role