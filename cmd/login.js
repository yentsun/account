// Generated by CoffeeScript 1.10.0
(function() {
  var jwt;

  jwt = require('jsonwebtoken');

  module.exports = function(seneca, options) {
    var cmd_login;
    cmd_login = function(params, respond) {
      var account_id, res, secret;
      account_id = params.account_id;
      res = {};
      secret = options.token_secret;
      res.token = jwt.sign({
        id: account_id
      }, secret, {
        noTimestamp: options.jwtNoTimestamp
      });
      return respond(null, res);
    };
    return cmd_login;
  };

}).call(this);

//# sourceMappingURL=login.js.map
