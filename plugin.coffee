authenticate = require './cmd/authenticate'
authorize = require './cmd/authorize'
identify = require './cmd/identify'
update = require './cmd/update'
verify = require './cmd/verify'
get = require './cmd/get'
issue_token = require './cmd/issue_token'
register = require './cmd/register'
delete_ = require './cmd/delete'
util = require './util'

module.exports = (options) ->
    seneca = @
    role = 'account'

    seneca.add "init:#{role}", (msg, respond) ->
        required = ['registration.starter_status', 'token.secret', 'authorization.acl']
        util.check_options options, required
        do respond
    seneca.add "role:#{role},cmd:authenticate", authenticate seneca
    seneca.add "role:#{role},cmd:authorize", authorize seneca, options.authorization
    seneca.add "role:#{role},cmd:identify", identify seneca
    seneca.add "role:#{role},cmd:update", update seneca
    seneca.add "role:#{role},cmd:verify", verify seneca, options.token
    seneca.add "role:#{role},cmd:get", get seneca
    seneca.add "role:#{role},cmd:issue_token", issue_token seneca, options.token
    seneca.add "role:#{role},cmd:register", register seneca, options.registration
    seneca.add "role:#{role},cmd:delete", delete_ seneca

    name: role