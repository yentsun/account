assert = require 'chai'
    .assert
sinon = require 'sinon'
acl = require 'acl'
util = require '../util'
acl_backend = new acl.memoryBackend()
acl = new acl acl_backend

ac_list = [
    roles: ['player']
    allows: [
        resources: 'profile'
        permissions: 'get'
    ]
]

options =
    test: true
    token_secret: 'secret'
    jwtNoTimestamp: true
    acl: acl
    starter_role: 'player'

log_mode = process.env.TEST_LOG_MODE or 'quiet'

seneca = require('seneca')(
    log: log_mode
    )
    .use '../plugin', options

account = seneca.pin
    role: 'account'
    cmd: '*'

describe 'register', () ->

    it 'registers new account', (done) ->
        account.register {email: 'good@email.com', password: 'pass'},
            (error, new_account) ->
                assert.equal new_account.id, 'good@email.com'
                assert.isNull error
                acl.userRoles new_account.id, (error, roles) ->
                    assert.include roles, 'player'
                    do done

    it 'silently fails if email is bad', (done) ->
        account.register {email: 'bad_email.com', password: 'pass'},
            (error, new_account) ->
                assert.isNull new_account
                assert.isNull error
                do done

    it 'silently fails when player is already registered', (done) ->
        account.register {email: 'already@there.com'}, (error, new_account) ->
            if new_account
                account.register {email: 'already@there.com', password: 'pass'},
                    (error, new_account) ->
                        assert.isNull new_account
                        assert.isNull error
                        do done

    it 'generates new password if its not set', (done) ->
        account.register {email: 'no@pass.com'}, (error, new_user) ->
            assert.equal new_user.password.length, 8
            do done

    it 'throws an error if starter role is not defined', (done) ->
        seneca.options.starter_role = null
        account.register {email: 'no@matter.com'}, (error, new_user) ->
            do done



describe 'authenticate', () ->

    email = 'newest@kid.com'

    before (done) ->
        account.register {email: email, password: 'somepassword'}, (error, res) ->
            do done

    it 'returns true if password is correct', (done) ->
        account.authenticate {account_id: email, password: 'somepassword'}, (error, result) ->
            assert.isTrue result.authenticated
            do done

    it 'returns false if password is bad', (done) ->
        account.authenticate {account_id: email, password: 'bad'}, (error, result) ->
            assert.isFalse result.authenticated
            do done

    it 'returns false if password is not sent', (done) ->
        account.authenticate {account_id: email}, (error, result) ->
            assert.isFalse result.authenticated
            do done

    it 'returns false if account is unidentified', (done) ->
        account.authenticate {account_id: 'doesntexist', password: 'doesntmatter'}, (error, result) ->
            assert.isFalse result.identified
            assert.isFalse result.authenticated
            do done

    it 'returns false if password sent is a float', (done) ->
        # this is needed to trigger `bcrypt.compare` error branch
        account.authenticate {account_id: email, password: 20.00}, (error, result) ->
            assert.isFalse result.authenticated
            do done

describe 'identify', () ->

    hash = null
    email = 'another@kid.com'

    before (done) ->
        account.register {email: email, password: 'somepassword'}, (error, res) ->
            hash = res.password_hash
            do done

    it 'returns account info if there is one', (done) ->
        account.identify {account_id: email}, (error, acc) ->
            assert.equal email, acc.id
            assert.equal hash, acc.password_hash
            do done

    it 'returns null if there is no account', (done) ->
        account.identify {account_id: 'no@account.com'}, (error, res) ->
            assert.equal null, res
            do done

    it 'returns null if there was an error while loading record', (done) ->
        entity = require '../node_modules/seneca/lib/entity'
        stub = sinon.stub entity.Entity.prototype, 'load$', (id, callback) ->
            error = new Error 'entity load error'
            callback error
        account.identify {account_id: email}, (error, res) ->
            assert.isNull res
            do stub.restore
            do done

describe 'login', () ->

    issued_token =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.' +
        'eyJpZCI6ImxvZ2dlZEBpbi5jb20ifQ.' +
        'BA59h_3VC84ocimYdg72auuEFd1vo8iZlJ8notcVrxs'

    before (done) ->
        account.register {email: 'logged@in.com', password: 'loggedpass'}, (error, res) ->
            do done

    it 'logs in a user', (done) ->
        account.login {account_id: 'logged@in.com', password: 'loggedpass'}, (error, res) ->
            assert.ok res.authenticated
            assert.equal issued_token, res.token
            do done

    it 'returns `authenticated:false` if password is incorrect', (done) ->
        account.login {account_id: 'logged@in.com', password: 'incorrect'}, (error, res) ->
            assert.isFalse res.authenticated
            do done

    it 'returns same token if a user already logged in', (done) ->
        account.login {account_id: 'logged@in.com', password: 'loggedpass'}, (error, res) ->
            assert.equal res.token, issued_token
            do done

describe 'authorize', () ->

    token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
            'eyJpZCI6ImF1dGhvcml6ZWRAcGxheWVyLmNvbSJ9.' +
            'WqzumznnQjadtYNUt_QYlbKEarmGT6I8Hvhre53UORU'

    before (before_done) ->
        acl.allow ac_list, (error) ->
            if error
                seneca.log.error 'acl load failed: ', error
            else
                account.register {email: 'authorized@player.com', password: 'authpass'}, (error, res) ->
                    do before_done

    it 'allows a registered player to view his profile', (done) ->
        account.authorize {token: token, resource: 'profile', action: 'get'}, (error, res) ->
            assert.isTrue res.authorized
            assert.isTrue res.token_verified
            assert.equal res.account_id, 'authorized@player.com'
            do done

    it 'does not allow a registered player to delete his profile', (done) ->
        account.authorize {token: token, resource: 'profile', action: 'delete'}, (error, res) ->
            assert.isFalse res.authorized
            assert.equal res.account_id, 'authorized@player.com'
            do done

    it 'does not authorize with a bad token', (done) ->
        account.authorize {token: 'bad.token'}, (error, result) ->
            assert.notOk result.passed
            do done

    it 'does not authorize with a verified token of unknown account', (done) ->
        account.authorize {token:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
            'eyJpZCI6InVua25vd25Aa2lkLmNvbSJ9.' +
            'gLjI4tqAbmxS5xItMo2IuX2-3XxK0DHCR8q-SuiCkwk'}, (error, res) ->
                assert.isFalse res.authorized
                do done

    it 'does not authorize with a verified token that has no id field', (done) ->
        account.authorize {token:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' +
            'eyJpZGUiOiJ3cm9uZ0BwbGF5ZXIuY29tIn0.' +
            'DtlP8pMWiwbamLv1VMgCXvKFb0t0vF6jnNRsVBChWnI'}, (error, res) ->
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
            non_required = 'some_value'
        assert.throws () ->
            util.check_options options, required
        do done

    it 'does not throw errors if all required options are present', (done) ->
        required = ['required_one', 'required_two']
        options =
            required_one: 1
            required_two: 2
        assert.doesNotThrow () ->
            util.check_options options, required
        do done


