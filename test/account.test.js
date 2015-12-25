// Generated by CoffeeScript 1.10.0
(function() {
  var ac_list, account, acl, acl_backend, assert, log_mode, options, profile, seneca, sinon;

  assert = require('chai').assert;

  sinon = require('sinon');

  acl = require('acl');

  acl_backend = new acl.memoryBackend();

  acl = new acl(acl_backend);

  ac_list = [
    {
      roles: ['player'],
      allows: [
        {
          resources: 'profile',
          permissions: 'get'
        }
      ]
    }
  ];

  options = {
    test: true,
    secret: 'secret',
    jwtNoTimestamp: true,
    acl: acl
  };

  log_mode = process.env.TEST_LOG_MODE || 'quiet';

  seneca = require('seneca')({
    log: log_mode
  }).use('../plugins/identify').use('../plugins/register', options).use('../plugins/authenticate', options).use('../plugins/authorize', options).use('../plugins/login', options).use('../plugins/profile', options);

  account = seneca.pin({
    plugin: '*'
  });

  profile = seneca.pin({
    plugin: 'profile',
    action: '*'
  });

  describe('register', function() {
    it('registers new account', function(done) {
      return account.register({
        email: 'good@email.com',
        password: 'pass'
      }, function(err, new_user) {
        if (err) {
          done(err);
        }
        assert.equal(new_user.id, 'good@email.com');
        return acl.userRoles(new_user.id, function(error, roles) {
          assert.include(roles, 'player');
          return done();
        });
      });
    });
    it('fails if email is bad', function(done) {
      return account.register({
        email: 'bad_email.com',
        password: 'pass'
      }, function(error, new_user) {
        assert.isUndefined(new_user);
        assert.equal('seneca: Bad email: bad_email.com', error.message);
        return done();
      });
    });
    it('fails when player is already registered', function(done) {
      return account.register({
        email: 'already@there.com'
      }, function(error, result) {
        if (result) {
          return account.register({
            email: 'already@there.com',
            password: 'pass'
          }, function(error, new_user) {
            assert.isUndefined(new_user);
            assert.equal('seneca: Already registered', error.message);
            return done();
          });
        }
      });
    });
    return it('generates new password if its not set', function(done) {
      return account.register({
        email: 'no@pass.com'
      }, function(error, new_user) {
        assert.equal(new_user.password.length, 8);
        return done();
      });
    });
  });

  describe('authenticate', function() {
    var email;
    email = 'newest@kid.com';
    before(function(done) {
      return account.register({
        email: email,
        password: 'somepassword'
      }, function(error, res) {
        return done();
      });
    });
    it('returns true if password is correct', function(done) {
      return account.authenticate({
        account_id: email,
        password: 'somepassword'
      }, function(error, result) {
        assert.isTrue(result.authenticated);
        return done();
      });
    });
    it('returns false if password is bad', function(done) {
      return account.authenticate({
        account_id: email,
        password: 'bad'
      }, function(error, result) {
        assert.isFalse(result.authenticated);
        return done();
      });
    });
    it('returns false if password is not sent', function(done) {
      return account.authenticate({
        account_id: email
      }, function(error, result) {
        assert.isFalse(result.authenticated);
        return done();
      });
    });
    it('returns false if account is unidentified', function(done) {
      return account.authenticate({
        account_id: 'doesntexist',
        password: 'doesntmatter'
      }, function(error, result) {
        assert.isFalse(result.identified);
        assert.isFalse(result.authenticated);
        return done();
      });
    });
    return it('returns false if password sent is a float', function(done) {
      return account.authenticate({
        account_id: email,
        password: 20.00
      }, function(error, result) {
        assert.isFalse(result.authenticated);
        return done();
      });
    });
  });

  describe('identify', function() {
    var email, hash;
    hash = null;
    email = 'another@kid.com';
    before(function(done) {
      return account.register({
        email: email,
        password: 'somepassword'
      }, function(error, res) {
        hash = res.password_hash;
        return done();
      });
    });
    it('returns account info if there is one', function(done) {
      return account.identify({
        account_id: email
      }, function(error, acc) {
        assert.equal(email, acc.id);
        assert.equal(hash, acc.password_hash);
        return done();
      });
    });
    it('returns null if there is no account', function(done) {
      return account.identify({
        account_id: 'no@account.com'
      }, function(error, res) {
        assert.equal(null, res);
        return done();
      });
    });
    return it('returns null if there was an error while loading record', function(done) {
      var entity, stub;
      entity = require('../node_modules/seneca/lib/entity');
      stub = sinon.stub(entity.Entity.prototype, 'load$', function(id, callback) {
        var error;
        error = new Error('entity load error');
        return callback(error);
      });
      return account.identify({
        account_id: email
      }, function(error, res) {
        assert.isNull(res);
        stub.restore();
        return done();
      });
    });
  });

  describe('login', function() {
    var issued_token;
    issued_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.' + 'eyJpZCI6ImxvZ2dlZEBpbi5jb20ifQ.' + 'BA59h_3VC84ocimYdg72auuEFd1vo8iZlJ8notcVrxs';
    before(function(done) {
      return account.register({
        email: 'logged@in.com',
        password: 'loggedpass'
      }, function(error, res) {
        return done();
      });
    });
    it('logs in a user', function(done) {
      return account.login({
        account_id: 'logged@in.com',
        password: 'loggedpass'
      }, function(error, res) {
        assert.ok(res.authenticated);
        assert.equal(issued_token, res.token);
        return done();
      });
    });
    it('returns `authenticated:false` if password is incorrect', function(done) {
      return account.login({
        account_id: 'logged@in.com',
        password: 'incorrect'
      }, function(error, res) {
        assert.isFalse(res.authenticated);
        return done();
      });
    });
    return it('returns same token if a user already logged in', function(done) {
      return account.login({
        account_id: 'logged@in.com',
        password: 'loggedpass'
      }, function(error, res) {
        assert.equal(res.token, issued_token);
        return done();
      });
    });
  });

  describe('authorize', function() {
    var token;
    token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' + 'eyJpZCI6ImF1dGhvcml6ZWRAcGxheWVyLmNvbSJ9.' + 'WqzumznnQjadtYNUt_QYlbKEarmGT6I8Hvhre53UORU';
    before(function(before_done) {
      return acl.allow(ac_list, function(error) {
        if (error) {
          return seneca.log.error('acl load failed: ', error);
        } else {
          return account.register({
            email: 'authorized@player.com',
            password: 'authpass'
          }, function(error, res) {
            return before_done();
          });
        }
      });
    });
    it('allows a registered player to view his profile', function(done) {
      return account.authorize({
        token: token,
        resource: 'profile',
        action: 'get'
      }, function(error, res) {
        assert.isTrue(res.authorized);
        assert.isTrue(res.token_verified);
        assert.equal(res.account_id, 'authorized@player.com');
        return done();
      });
    });
    it('does not allow a registered player to delete his profile', function(done) {
      return account.authorize({
        token: token,
        resource: 'profile',
        action: 'delete'
      }, function(error, res) {
        assert.isFalse(res.authorized);
        assert.equal(res.account_id, 'authorized@player.com');
        return done();
      });
    });
    it('does not authorize with a bad token', function(done) {
      return account.authorize({
        token: 'bad.token'
      }, function(error, result) {
        assert.notOk(result.passed);
        return done();
      });
    });
    it('does not authorize with a verified token of unknown account', function(done) {
      return account.authorize({
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' + 'eyJpZCI6InVua25vd25Aa2lkLmNvbSJ9.' + 'gLjI4tqAbmxS5xItMo2IuX2-3XxK0DHCR8q-SuiCkwk'
      }, function(error, res) {
        assert.isFalse(res.authorized);
        return done();
      });
    });
    it('does not authorize with a verified token that has no id field', function(done) {
      return account.authorize({
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.' + 'eyJpZGUiOiJ3cm9uZ0BwbGF5ZXIuY29tIn0.' + 'DtlP8pMWiwbamLv1VMgCXvKFb0t0vF6jnNRsVBChWnI'
      }, function(error, res) {
        assert.isTrue(res.token_verified);
        assert.isFalse(res.authorized);
        return done();
      });
    });
    it('does not authorize with a verified token if there is an acl error', function(done) {
      sinon.stub(acl, 'isAllowed', function(account_id, resource, action, callback) {
        var error;
        error = new Error('an acl error');
        return callback(error);
      });
      return account.authorize({
        token: token,
        resource: 'profile',
        action: 'get'
      }, function(error, res) {
        assert.isTrue(res.token_verified);
        assert.isFalse(res.authorized);
        sinon.restore();
        return done();
      });
    });
    return it('denies an anonymous user to view profile', function(done) {
      return account.authorize({
        token: null,
        resource: 'profile',
        permission: 'view'
      }, function(error, res) {
        assert.isFalse(res.authorized);
        return done();
      });
    });
  });

  describe('plugin:profile', function() {
    before(function(done) {
      account.register({
        email: 'authorized@player.com',
        password: 'authpass'
      }, function(error, res) {
        profile.update({
          account_id: 'authorized@player.com',
          data: {
            name: 'Auth Playa'
          }
        });
        return done();
      });
      account.register({
        email: 'authorized@player2.com',
        password: 'authpass'
      }, function(error, res) {
        profile.update({
          account_id: 'authorized@player2.com',
          data: {
            name: 'Auth Playa Two'
          }
        });
        return done();
      });
      return account.register({
        email: 'authorized@player3.com',
        password: 'authpass'
      }, function(error, res) {
        return done();
      });
    });
    it('creates new profile', function(done) {
      return profile.update({
        account_id: 'authorized@player3.com',
        data: {
          name: 'New Kid Three'
        }
      }, function(error, res) {
        assert.equal(res.name, 'New Kid Three');
        return done();
      });
    });
    it('updates existing profile', function(done) {
      return profile.update({
        account_id: 'authorized@player2.com',
        data: {
          name: 'New Kid'
        }
      }, function(error, res) {
        assert.equal(res.name, 'New Kid');
        return done();
      });
    });
    return it('returns profile dict', function(done) {
      return profile.get({
        account_id: 'authorized@player.com'
      }, function(error, res) {
        assert.equal(res.name, 'Auth Playa');
        return done();
      });
    });
  });

}).call(this);

//# sourceMappingURL=account.test.js.map
