bcrypt = require 'bcryptjs'
validator = require 'validator'
util = require './../util'

module.exports = (seneca, options) ->
    acl = options.acl
    password_length = options.password_length or 8
    account = seneca.pin
        role: 'account'
        cmd: '*'

    cmd_register = (args, respond) ->
        email = args.email
        password = args.password or util.generate_password password_length

        # check validity
        if !validator.isEmail email
            seneca.log.warn 'bad email', email
            return respond null, null

        # check for registered accounts
        account.identify {account_id: email}, (error, account) ->
            if account
                seneca.log.warn 'account already registered', account.id
                respond null, null
            else
                # hash password
                bcrypt.genSalt 10, (error, salt) ->
                    if error
                        seneca.log.error 'salt generation failed:', error.message
                        return respond error, null
                    bcrypt.hash password, salt, (error, hash) ->
                        if error
                            seneca.log.error 'password hash failed:', error.message
                            return respond error, null

                        # create new user record
                        new_account = seneca.make 'account'
                        new_account.id = email
                        new_account.password_hash = hash
                        new_account.save$ (error, saved_account) ->
                            if error
                                seneca.log.error 'new account record failed:', error.message
                                return respond error, null
                            # assign `player` role
                            acl.addUserRoles saved_account.id, ['player'], (error) ->
                                if error
                                    seneca.log.error 'adding role to new account failed:', error.message
                                    account.remove {account_id: saved_account.id}, (error, removed_account) ->
                                        return respond error, null
                                saved_account.password = password
                                respond null, saved_account
    cmd_register
