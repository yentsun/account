authenticate = require './cmd/authenticate'
authorize = require './cmd/authorize'
identify = require './cmd/identify'
get = require './cmd/get'
issue_token = require './cmd/issue_token'
register = require './cmd/register'
delete_ = require './cmd/delete'
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
    seneca.add "role:#{role},cmd:get", get seneca, options
    seneca.add "role:#{role},cmd:issue_token", issue_token seneca, options
    seneca.add "role:#{role},cmd:register", register seneca, options
    seneca.add "role:#{role},cmd:delete", delete_ seneca, options
    name: role