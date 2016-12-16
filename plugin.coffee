authenticate = require './cmd/authenticate'
identify = require './cmd/identify'
update = require './cmd/update'
verify = require './cmd/verify'
get = require './cmd/get'
issue_token = require './cmd/issue_token'
encrypt = require './cmd/encrypt'
register = require './cmd/register'
delete_ = require './cmd/delete'
list = require './cmd/list'
util = require './util'

module.exports = (options) ->
    seneca = @
    role = 'account'

    seneca.add "init:#{role}", (msg, respond) ->
        required = ['registration.starter_status', 'token.secret']
        util.check_options options, required
        do respond
    seneca.add "role:#{role},cmd:authenticate", authenticate seneca
    seneca.add "role:#{role},cmd:identify", identify seneca, options
    seneca.add "role:#{role},cmd:update", update seneca, options
    seneca.add "role:#{role},cmd:verify", verify seneca, options.token
    seneca.add "role:#{role},cmd:get", get seneca, options
    seneca.add "role:#{role},cmd:issue_token", issue_token seneca, options.token
    seneca.add "role:#{role},cmd:encrypt", encrypt seneca, options
    seneca.add "role:#{role},cmd:register", register seneca, options
    seneca.add "role:#{role},cmd:delete", delete_ seneca, options
    seneca.add "role:#{role},cmd:list", list seneca, options

    name: role