assert = require 'chai'
    .assert
bcrypt = require 'bcryptjs'
sinon = require 'sinon'
acl = require 'acl'
jwt = require 'jsonwebtoken'
moment = require 'moment'
util = require '../util'
acl_backend = new acl.memoryBackend()
acl = new acl acl_backend
seneca_entity = require '../node_modules/seneca/lib/entity'
    .Entity.prototype

ac_list = [
    roles: ['new']
    allows: [
        resources: 'profile'
        permissions: 'get'
    ]
]

token_secret = 'КI7(#*ØḀQ#p%pЗRsN?'

options =
    test: true
    token_secret: token_secret
    jwtNoTimestamp: true
    acl: acl
    starter_role: 'new'

log_mode = process.env.TEST_LOG_MODE or 'quiet'

seneca = require('seneca')(
    log: log_mode
    )
    .use '../plugin', options
    .client()

account = seneca.pin
    role: 'account'
    cmd: '*'

describe 'register', () ->

    it 'registers new account and assert no password in response', (done) ->
        account.register {email: 'good@email.com', password: 'pass'},
            (error, new_account) ->
                assert.equal new_account.email, 'good@email.com'
                assert.isNull error
                assert.isUndefined new_account.password
                assert.equal new_account.registered_at, do moment().format
                assert.equal new_account.role, 'new'
                jwt.verify new_account.token, token_secret, (error, decoded) ->
                    assert.equal decoded.id, new_account.id
                    assert.equal decoded.reason, 'conf'
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

    it 'fails if there is a salt generation error', (done) ->
        stub = sinon.stub bcrypt, 'genSalt', (length, callback) ->
            callback new Error 'bcrypt salt generation error'
        account.register {email: 'good1@email.com', password: 'pass'}, (error, new_user) ->
            do stub.restore
            assert.isNull new_user
            assert.equal error.message, 'seneca: Action cmd:register,role:account failed: bcrypt salt generation error.'
            do done

    it 'fails if there is a hash generation error', (done) ->
        stub = sinon.stub bcrypt, 'hash', (password, salt, callback) ->
            callback new Error 'bcrypt hash generation error'
        account.register {email: 'good2@email.com', password: 'pass'}, (error, new_user) ->
            do stub.restore
            assert.isNull new_user
            assert.equal error.message, 'seneca: Action cmd:register,role:account failed: bcrypt hash generation error.'
            do done

    it 'fails if there is a storage error', (done) ->
        stub = sinon.stub seneca_entity, 'save$', (callback) ->
            callback new Error 'seneca save$ error'
        account.register {email: 'good3@email.com', password: 'pass'}, (error, new_user) ->
            do stub.restore
            assert.isNull new_user
            assert.equal error.message, 'seneca: Action cmd:register,role:account failed: seneca save$ error.'
            do done


describe 'authenticate', () ->

    email = 'newest@kid.com'

    before (done) ->
        account.register {email: email, password: 'somepassword'}, (error, res) ->
            do done

    it 'returns true if password is correct', (done) ->
        account.authenticate {email: email, password: 'somepassword'}, (error, result) ->
            assert.isTrue result.authenticated
            do done

    it 'returns false if password is bad', (done) ->
        account.authenticate {email: email, password: 'bad'}, (error, result) ->
            assert.isFalse result.authenticated
            do done

    it 'returns false if password is not sent', (done) ->
        account.authenticate {email: email}, (error, result) ->
            assert.isFalse result.authenticated
            do done

    it 'returns false if account is unidentified', (done) ->
        account.authenticate {email: 'doesntexist', password: 'doesntmatter'}, (error, result) ->
            assert.isFalse result.identified
            assert.isFalse result.authenticated
            do done

    it 'returns false if password sent is a float', (done) ->
        # this is needed to trigger `bcrypt.compare` error branch
        account.authenticate {email: email, password: 20.00}, (error, result) ->
            assert.isFalse result.authenticated
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

    it 'logs in a user', (done) ->
        account.issue_token {account_id: id}, (error, res) ->
            jwt.verify res.token, token_secret, (error, decoded) ->
                assert.equal decoded.id, id
                assert.equal decoded.reason, 'auth'
                assert.equal res.reason, 'auth'
                do done

    it 'returns a confirmation token', (done) ->
        account.issue_token {account_id: id, reason: 'conf'}, (error, res) ->
            jwt.verify res.token, token_secret, (error, decoded) ->
                assert.equal decoded.id, id
                assert.equal decoded.reason, 'conf'
                do done


describe 'authorize', () ->

    token = null

    before (before_done) ->
        acl.allow ac_list, (error) ->
            if error
                seneca.log.error 'acl load failed: ', error
            else
                account.register {email: 'authorized@player.com', password: 'authpass'}, (error, res) ->
                    account.issue_token {account_id: res.id}, (error, res) ->
                        token = res.token
                        do before_done

    it 'allows a registered player to view his profile', (done) ->
        account.authorize {token: token, resource: 'profile', action: 'get'}, (error, res) ->
            assert.isTrue res.authorized
            assert.isTrue res.token_verified
            do done

    it 'does not allow a registered player to delete his profile', (done) ->
        account.authorize {token: token, resource: 'profile', action: 'delete'}, (error, res) ->
            assert.isFalse res.authorized
            do done

    it 'does not authorize with a bad token', (done) ->
        account.authorize {token: 'bad.token'}, (error, res) ->
            assert.isFalse res.token_verified
            assert.isFalse res.authorized
            do done

    it 'does not authorize with a verified token of unknown account', (done) ->
        account.issue_token {account_id: 'rubbish_acc_id'}, (error, res) ->
            tkn = res.token
            account.authorize {token: tkn}, (error, res) ->
                assert.isTrue res.token_verified
                assert.isFalse res.authorized
                do done

    it 'does not authorize with a verified token that has no id field', (done) ->
        account.authorize {token:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
            'eyJydWJiaXNoIjo1MzM0NTN9.' +
            '8r05YmeNag4q0QtToIqKmUSoz1y2hxlFlPnitNqvpf4'}, (error, res) ->
                assert.isTrue res.token_verified
                assert.isFalse res.authorized
                do done

    it 'does not authorize with a verified token if there is an acl error', (done) ->
        sinon.stub acl, 'isAllowed', (account_id, resource, action, callback) ->
            error = new Error 'an acl error'
            callback error
        account.authorize {token: token, resource: 'profile', action: 'get'}, (error, res) ->
            assert.isTrue res.token_verified
            assert.isFalse res.authorized
            do sinon.restore
            do done

    it 'denies an anonymous user to view profile', (done) ->
        account.authorize {token: null, resource: 'profile', permission: 'view'}, (error, res) ->
            assert.isFalse res.authorized
            do done

    it 'fails if there is an acl error on adding a role', (done) ->
        sinon.stub acl, 'addUserRoles', (id, roles, callback) ->
            callback new Error 'acl error while adding roles'
        account.authorize {token: token, resource: 'profile', action: 'get'}, (error, res) ->
            assert.isNull res
            assert.include error.message, 'acl error while adding roles'
            do sinon.restore
            do done

describe 'confirm', () ->

    before: (done) ->
        account.register {email: 'confirmed@player.com', password: 'authpass'}, (error, res) ->
            do done

    it 'confirms a new user by the token', (done) ->
        do done


describe 'delete', () ->

    before: (done) ->
        account.register {email: 'victim@player.com', password: 'authpass'}, (error, res) ->
            account.identify {email: 'victim@player.com'}, (error, res) ->
                assert.equal res.id, 'victim@player.com'
                do done

    it 'deletes a registered account and makes sure it is not present any more', (done) ->
        account.delete {email: 'victim@player.com'}, (error, res) ->
            assert.isNull error
            assert.isNull res
            account.identify {email: 'victim@player.com'}, (error, res) ->
                assert.notOk res
                do done

    it 'returns nothing id there is no such account', (done) ->
        account.delete {email: 'stranger@player.com'}, (error, res) ->
            assert.isNull error
            assert.isNull res
            do done

    it 'returns error if deletion failed', (done) ->
        stub = sinon.stub seneca_entity, 'remove$', (id, callback) ->
            error = new Error 'entity removal error'
            callback error
        account.delete {email: 'victim@player.com'}, (error, res) ->
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
        required = ['required']
        options =
            non_required: 'some_value'
        assert.throws () ->
            util.check_options options, required
        , 'required option required not defined'
        do done

    it 'does not throw errors if all required options are present', (done) ->
        required = ['required_one', 'required_two']
        options =
            required_one: 1
            required_two: 2
        assert.doesNotThrow () ->
            util.check_options options, required
        do done


