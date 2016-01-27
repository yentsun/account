bcrypt = require 'bcryptjs'
validator = require 'validator'
moment = require 'moment'
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
            seneca.log.warn 'invalid email', email
            return respond null,
                message: 'invalid email'

        # check for registered accounts
        account.identify {email: email}, (error, acc) ->
            if acc
                seneca.log.warn 'account already registered', acc.email
                respond null,
                    message: 'account already registered'
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
                        # create new user record
                        new_account = seneca.make 'account'
                        new_account.email = email
                        new_account.hash = hash
                        new_account.registered_at = do moment().format
                        new_account.role = starter_role
                        new_account.save$ (error, saved_account) ->
                            if error
                                seneca.log.error 'new account record failed:', error.message
                                return respond error, null
                            if saved_account
                                # send pack password if it has been generated
                                saved_account.password = password if password_generated
                                # issue a confirmation token
                                seneca.log.debug 'new account saved, issuing the conf token...'
                                account.issue_token {account_id: saved_account.id, reason: 'conf'}, (error, res) ->
                                    if error
                                        seneca.log.error 'confirmation token issue failed', error.message
                                        return respond error, null
                                    saved_account.token = res.token
                                    respond null, saved_account
    cmd_register
