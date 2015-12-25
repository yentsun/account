bcrypt = require 'bcryptjs'
validator = require 'validator'
util = require './../util'

module.exports = (seneca, options) ->
    acl = options.acl

    cmd_register = (args, respond) ->
        email = args.email
        password = args.password or util.generate_password()

        # check validity
        if !validator.isEmail email
            respond seneca.fail "Bad email: #{email}"

        # check for registered accounts
        seneca.act 'role:account,cmd:identify', {account_id: email}, (error, account) ->
            if account
                respond seneca.fail 'Already registered'
            else
                # hash password
                bcrypt.genSalt 10, (error, salt) ->
                    bcrypt.hash password, salt, (error, hash) ->

                        # create new user record
                        new_account = seneca.make 'account'
                        new_account.id = email
                        new_account.password_hash = hash
                        new_account.group = 'general'
                        new_account.save$ (error, saved_account) ->
                            # assign `player` role
                            acl.addUserRoles saved_account.id, ['player'], (error) ->
                                if error
                                    seneca.log.error 'role assignment failed', saved_account.id
                                    respond error
                                else
                                    saved_account.password = password
                                    respond null, saved_account
    cmd_register
