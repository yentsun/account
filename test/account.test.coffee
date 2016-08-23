assert = require 'chai'
    .assert
bcrypt = require 'bcryptjs'
sinon = require 'sinon'
jwt = require 'jsonwebtoken'
moment = require 'moment'
util = require '../util'
seneca_entity = require '../node_modules/seneca/lib/entity'
    .Entity.prototype


token_secret = 'КI7(#*ØḀQ#p%pЗRsN?'

options =
    zone: 'zone'
    base: 'base'
    test: true
    token:
        secret: token_secret
        jwtNoTimestamp: true
    registration:
        starter_status: 'new'

log_mode = process.env.TEST_LOG_MODE or 'quiet'

seneca = require('seneca')(
    log: log_mode
    debug:
        undead: true
        short_logs: true
        fragile: true
    )
    .use '../plugin', options
    .client()

account = seneca.pin
    role: 'account'
    cmd: '*'

describe 'register', () ->

    it 'registers new account with password and assert no password in response', (done) ->
        account.register {email: 'gOOd@email.com', password: 'pass'},
            (error, new_account) ->
                assert.equal new_account.email, 'good@email.com'
                assert.isNull error
                assert.isUndefined new_account.password
                assert.equal new_account.registered_at, do moment().format
                assert.equal new_account.status, 'new'
                jwt.verify new_account.token, token_secret, (error, decoded) ->
                    assert.equal decoded.id, new_account.id
                    assert.equal decoded.aud, 'email'
                    do done

    it 'registers a new account without password and with `confirmed` status', (done) ->
        account.register {email: 'conf@email.com', status: 'confirmed'},
            (error, new_account) ->
                assert.equal new_account.email, 'conf@email.com'
                assert.equal new_account.status, 'confirmed'
                do done

    it 'fails if email is invalid', (done) ->
        account.register {email: 'bad_email.com', password: 'pass'},
            (error, res) ->
                assert.isNull error
                assert.equal res.message, 'invalid email'
                do done

    it 'fails when player is already registered', (done) ->
        account.register {email: 'already@there.com'}, (error, new_account) ->
            if new_account
                account.register {email: 'already@there.com', password: 'pass'},
                    (error, res) ->
                        assert.isNull error
                        assert.equal res.message, 'account already registered'
                        do done

    it 'generates new password if its not set', (done) ->
        account.register {email: 'no@pass.com'}, (error, new_user) ->
            assert.equal new_user.password.length, 8
            do done

    it 'fails if there is a storage error', (done) ->
        stub = sinon.stub seneca_entity, 'save$', (callback) ->
            callback new Error 'seneca save$ error'
        account.register {email: 'good3@email.com', password: 'pass'}, (error, new_user) ->
            do stub.restore
            assert.isNull new_user
            assert.equal error.message, 'seneca: Action cmd:register,role:account failed: seneca save$ error.'
            do done

describe 'encrypt', () ->

    it 'fails if there is a salt generation error', (done) ->
        stub = sinon.stub bcrypt, 'genSalt', (length, callback) ->
            callback new Error 'bcrypt salt generation error'
        account.encrypt {subject: 'pass'}, (error, res) ->
            do stub.restore
            assert.isNull res
            assert.equal error.message, 'seneca: Action cmd:encrypt,role:account failed: bcrypt salt generation error.'
            do done

    it 'fails if there is a hash generation error', (done) ->
        stub = sinon.stub bcrypt, 'hash', (password, salt, callback) ->
            callback new Error 'bcrypt hash generation error'
        account.encrypt {subject: 'pass'}, (error, res) ->
            do stub.restore
            assert.isNull res
            assert.equal error.message, 'seneca: Action cmd:encrypt,role:account failed: bcrypt hash generation error.'
            do done


describe 'authenticate', () ->

    email = 'newest@kid.com'

    before (done) ->
        account.register {email: email, password: 'somepassword'}, (error, res) ->
            do done

    it 'returns true if password is correct', (done) ->
        account.authenticate {email: email, password: 'somepassword'}, (error, result) ->
            assert.isOk result.id
            assert.equal result.email, email
            do done

    it 'returns true if email is set uppercase', (done) ->
        account.authenticate {email: 'NEWEST@kid.com', password: 'somepassword'}, (error, result) ->
            assert.isOk result.id
            assert.equal result.email, email
            do done

    it 'returns false if password is bad', (done) ->
        account.authenticate {email: email, password: 'bad'}, (error, result) ->
            assert.isNull result
            do done

    it 'returns false if password is not sent', (done) ->
        account.authenticate {email: email}, (error, result) ->
            assert.isNull result
            do done

    it 'returns false if account is unidentified', (done) ->
        account.authenticate {email: 'doesntexist', password: 'doesntmatter'}, (error, result) ->
            assert.isNull result
            do done

    it 'returns false if password sent is a float', (done) ->
        # this is needed to trigger `bcrypt.compare` error branch
        account.authenticate {email: email, password: 20.00}, (error, result) ->
            assert.isNull result
            do done


describe 'identify', () ->

    hash = null
    id = null
    email = 'another@kid.com'

    before (done) ->
        account.register {email: email, password: 'somepassword'}, (error, res) ->
            hash = res.hash
            id = res.id
            do done

    it 'returns account info if there is one', (done) ->
        account.identify {email: email}, (error, acc) ->
            assert.equal email, acc.email
            assert.equal hash, acc.hash
            assert.equal id, acc.id
            do done

    it 'returns null if there is no account', (done) ->
        account.identify {email: 'no@account.com'}, (error, res) ->
            assert.equal null, res
            do done

    it 'returns null if there was an error while loading record', (done) ->
        stub = sinon.stub seneca_entity, 'list$', (filter, callback) ->
            error = new Error 'entity load error'
            callback error
        account.identify {email: email}, (error, res) ->
            assert.isNull res
            do stub.restore
            do done


describe 'issue_token', () ->

    id = null

    before (done) ->
        account.register {email: 'logged@in.com'}, (error, res) ->
            id = res.id
            do done

    it 'allows any payload to be encoded', (done) ->
        account.issue_token {account_id: id, payload: {any: 'value'}}, (error, res) ->
            jwt.verify res.token, token_secret, (error, decoded) ->
                assert.equal decoded.id, id
                assert.equal decoded.aud, 'web'
                assert.equal decoded.any, 'value'
                do done

    it 'returns a confirmation token', (done) ->
        account.issue_token {account_id: id, aud: 'email'}, (error, res) ->
            jwt.verify res.token, token_secret, (error, decoded) ->
                assert.equal decoded.id, id
                assert.equal decoded.aud, 'email'
                do done


describe 'get', () ->

    it 'returns error if it failed to get record from storage', (done) ->
        id = null
        account.register {email: 'failed@user.com', password: 'authpass'}, (error, res) ->
            id = res.id
            stub = sinon.stub seneca_entity, 'load$', (id, callback) ->
                error = new Error 'seneca load$ error'
                callback error
            account.get {account_id: id}, (error) ->
                assert.include error.message, 'seneca load$ error'
                do stub.restore
                do done


describe 'update', () ->

    id = null

    before (done) ->
        account.register {email: 'to_update@user.com', password: 'authpass'}, (error, res) ->
            id = res.id
            do done

    it 'updates a user status to `confirmed`', (done) ->
        account.update {account_id: id, status: 'confirmed'}, (error, upd_acc) ->
            assert.equal upd_acc.status, 'confirmed'
            assert.equal upd_acc.updated[0], 'status'
            do done

    it 'does not actually update again the user status to `confirmed`', (done) ->
        account.update {account_id: id, status: 'confirmed'}, (error, upd_acc) ->
            assert.equal upd_acc.status, 'confirmed'
            assert.equal(upd_acc.updated.length, 0);
            do done

    it 'updates a user password', (done) ->
        account.update {account_id: id, password: 'newpass'}, (error, upd_acc) ->
            assert.equal upd_acc.email, 'to_update@user.com'
            assert.equal upd_acc.updated[0], 'password'
            account.authenticate {email: 'to_update@user.com', password: 'newpass'}, (error, res) ->
                assert.isOk res.id
                assert.equal res.email, 'to_update@user.com'
                do done

    it 'fails to update if there is a load error', (done) ->
        stub = sinon.stub seneca_entity, 'load$', (id, callback) ->
            error = new Error 'seneca load$ error'
            callback error
        account.update {account_id: id, password: 'newestpass'}, (error, upd_acc) ->
            assert.include error.message, 'seneca load$ error'
            do stub.restore
            do done

    it 'fails to update if there is a save$ error', (done) ->
        stub = sinon.stub seneca_entity, 'save$', (callback) ->
            error = new Error 'seneca save$ error'
            callback error
        account.update {account_id: id, password: 'newestpass'}, (error, upd_acc) ->
            assert.include error.message, 'seneca save$ error'
            do stub.restore
            do done

    it 'fails to update if there is no such accountId', (done) ->
        account.update {account_id: 'WERD01', password: 'newestpass'}, (error, upd_acc) ->
            assert.include error.message, 'tried to update nonexistent account WERD01'
            do done


describe 'delete', () ->

    id = null

    before (done) ->
        account.register {email: 'victim@player.com', password: 'authpass'}, (error, res) ->
            account.identify {email: 'victim@player.com'}, (error, res) ->
                id = res.id
                do done

    it 'deletes a registered account and makes sure it is not present any more', (done) ->
        account.delete {account_id: id}, (error, res) ->
            assert.isNull error
            assert.isNull res
            account.identify {email: 'victim@player.com'}, (error, res) ->
                assert.notOk res
                do done

    it 'returns nothing id there is no such account', (done) ->
        account.delete {account_id: 'stranger@player.com'}, (error, res) ->
            assert.isNull error
            assert.isNull res
            do done

    it 'returns error if deletion failed', (done) ->
        stub = sinon.stub seneca_entity, 'remove$', (id, callback) ->
            error = new Error 'entity removal error'
            callback error
        account.delete {account_id: id}, (error, res) ->
            do stub.restore
            assert.equal error.message, 'seneca: Action cmd:delete,role:account failed: entity removal error.'
            assert.isNull res
            do done


describe 'util.generate_password', () ->

    it 'throws an error if length is more than 256', (done) ->
        bad_gen_pass = () ->
            util.generate_password 8, 'abcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+'+
                                      'abcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+a'+
                                      'bcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+abcde'+
                                      'fABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+abcdefABCDEF&^$012345_*+'
        assert.throws bad_gen_pass
        do done


describe 'util.check_options', () ->

    it 'throws an error if a required option is not present', (done) ->
        required = ['module.required']
        options =
            module:
                non_required: 'some_value'
        assert.throws () ->
            util.check_options options, required
        , 'required option module.required not defined'
        do done

    it 'does not throw errors if all required options are present', (done) ->
        required = ['required.one', 'required.two']
        options =
            required:
                one: 1
                two: 2
        assert.doesNotThrow () ->
            util.check_options options, required
        do done


