// Generated by CoffeeScript 1.10.0
(function() {
  var bcrypt;

  bcrypt = require('bcryptjs');

  module.exports = function(seneca, options) {
    var cmd_encrypt;
    cmd_encrypt = function(args, respond) {
      var subject;
      subject = args.subject;
      return bcrypt.genSalt(10, function(error, salt) {
        if (error) {
          seneca.log.error('salt generation failed:', error.message);
          return respond(error, null);
        }
        return bcrypt.hash(subject, salt, function(error, hash) {
          if (error) {
            seneca.log.error('hash failed:', error.message);
            return respond(error, null);
          }
          return respond(null, {
            hash: hash
          });
        });
      });
    };
    return cmd_encrypt;
  };

}).call(this);

//# sourceMappingURL=encrypt.js.map
