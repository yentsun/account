bcrypt = require 'bcryptjs'
validator = require 'validator'
util = require './../util'

module.exports = (seneca, options) ->
    acl = options.acl
    starter_role = options.starter_role
    password_length = options.password_length or 8
    password_generated = false
    account = seneca.pin
        role: 'account'
        cmd: '*'

    cmd_register = (args, respond) ->
        email = args.email

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
                password = args.password
                if !password
                    seneca.log.debug 'generating password'
                    password = util.generate_password password_length
                    password_generated = true
                # hash password
                bcrypt.genSalt 10, (error, salt) ->
                    if error
                        seneca.log.error 'salt generation failed:', error.message
                        return respond error, null
                    bcrypt.hash password, salt, (error, hash) ->
                        if error
                            seneca.log.error 'password hash failed:', error.message
                            return respond error, null

                        seneca.log.debug 'assigning starter role', starter_role
                        acl.addUserRoles email, [starter_role], (error) ->
                            if error
                                seneca.log.error 'adding starter role to new account failed:', error.message
                                return respond error, null
                            else
                                # create new user record
                                new_account = seneca.make 'account'
                                new_account.id = email
                                new_account.password_hash = hash
                                new_account.save$ (error, saved_account) ->
                                    if error
                                        seneca.log.error 'new account record failed:', error.message
                                        respond error, null
                                    if saved_account
                                        saved_account.password = password if password_generated
                                        respond null, saved_account
    cmd_register
