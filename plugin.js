// Generated by CoffeeScript 1.10.0
(function() {
  var authenticate, authorize, delete_, encrypt, get, identify, issue_token, register, update, util, verify;

  authenticate = require('./cmd/authenticate');

  authorize = require('./cmd/authorize');

  identify = require('./cmd/identify');

  update = require('./cmd/update');

  verify = require('./cmd/verify');

  get = require('./cmd/get');

  issue_token = require('./cmd/issue_token');

  encrypt = require('./cmd/encrypt');

  register = require('./cmd/register');

  delete_ = require('./cmd/delete');

  util = require('./util');

  module.exports = function(options) {
    var role, seneca;
    seneca = this;
    role = 'account';
    seneca.add("init:" + role, function(msg, respond) {
      var required;
      required = ['registration.starter_status', 'token.secret'];
      util.check_options(options, required);
      return respond();
    });
    seneca.add("role:" + role + ",cmd:authenticate", authenticate(seneca));
    seneca.add("role:" + role + ",cmd:identify", identify(seneca, options));
    seneca.add("role:" + role + ",cmd:update", update(seneca, options));
    seneca.add("role:" + role + ",cmd:verify", verify(seneca, options.token));
    seneca.add("role:" + role + ",cmd:get", get(seneca, options));
    seneca.add("role:" + role + ",cmd:issue_token", issue_token(seneca, options.token));
    seneca.add("role:" + role + ",cmd:encrypt", encrypt(seneca, options));
    seneca.add("role:" + role + ",cmd:register", register(seneca, options));
    seneca.add("role:" + role + ",cmd:delete", delete_(seneca, options));
    return {
      name: role
    };
  };

}).call(this);

//# sourceMappingURL=plugin.js.map
