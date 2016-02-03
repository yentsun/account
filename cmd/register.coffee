validator = require 'validator'
moment = require 'moment'
util = require './../util'

module.exports = (seneca, options) ->
    starter_status = options.starter_status
    password_length = options.password_length or 8
    password_generated = false
    account = seneca.pin
        role: 'account'
        cmd: '*'

    cmd_register = (args, respond) ->

        email = args.email.toLowerCase()
        status = args.status or starter_status

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
                account.encrypt {subject: password}, (error, res) ->
                    if error
                        seneca.log.error 'password encrypt failed:', error.message
                        return respond error, null
                    hash = res.hash
                    # create new user record
                    new_account = seneca.make 'account'
                    new_account.email = email
                    new_account.hash = hash
                    new_account.registered_at = do moment().format
                    new_account.status = status
                    new_account.save$ (error, saved_account) ->
                        if error
                            seneca.log.error 'new account record failed:', error.message
                            return respond error, null
                        if saved_account
                            seneca.log.debug 'new account saved'
                            # send pack password if it has been generated
                            saved_account.password = password if password_generated
                            if status == 'confirmed'
                                # do not issue confirmation token
                                return respond null, saved_account
                            else
                                # issue a confirmation token
                                seneca.log.debug 'issuing the conf token...'
                                account.issue_token {account_id: saved_account.id, reason: 'conf'}, (error, res) ->
                                    if error
                                        seneca.log.error 'confirmation token issue failed', error.message
                                        return respond error, null
                                    saved_account.token = res.token
                                    respond null, saved_account
    cmd_register
