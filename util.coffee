crypto = require 'crypto'

module.exports =

    ###
    Generates random password
    credit: http://stackoverflow.com/a/25690754/216042
    ###
    generate_password: (length, chars='abcdefABCDEF&^$012345_*+') ->

        if chars.length > 256
            throw new Error "Argument 'chars' should not have more than 256 characters otherwise
                             unpredictability will be broken"

        random_bytes = crypto.randomBytes length
        result = new Array length
        cursor = 0

        i = 0
        while i <= length
            cursor += random_bytes[i]
            result[i] = chars[cursor % chars.length]
            i += 1

        result.join ''
