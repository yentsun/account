jwt = require 'jsonwebtoken'

module.exports = (seneca, options) ->

    cmd_verify = (args, respond) ->
        token = args.token
        secret = options.secret
        response =
            token_verified: false

        jwt.verify token, secret, (error, decoded) ->
            if error
                seneca.log.debug 'token verification error', error.message
                return respond null, response

            seneca.log.debug 'token verified'
            response.token_verified = true
            response.decoded = decoded
            respond null, response
    cmd_verify
