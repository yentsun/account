bcrypt = require 'bcryptjs'

module.exports = (seneca) ->

    cmd_encrypt = (args, respond) ->
        subject = args.subject
        bcrypt.genSalt 10, (error, salt) ->
            if error
                seneca.log.error 'salt generation failed:', error.message
                return respond error, null
            bcrypt.hash subject, salt, (error, hash) ->
                if error
                    seneca.log.error 'hash failed:', error.message
                    return respond error, null
                return respond null,
                    hash: hash

    cmd_encrypt
