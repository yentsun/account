// Generated by CoffeeScript 1.10.0
(function() {
  var bcrypt, moment, util, validator;

  bcrypt = require('bcryptjs');

  validator = require('validator');

  moment = require('moment');

  util = require('./../util');

  module.exports = function(seneca, options) {
    var account, cmd_register, password_generated, password_length, starter_status;
    starter_status = options.starter_status;
    password_length = options.password_length || 8;
    password_generated = false;
    account = seneca.pin({
      role: 'account',
      cmd: '*'
    });
    cmd_register = function(args, respond) {
      var email, status;
      email = args.email;
      status = args.status || starter_status;
      if (!validator.isEmail(email)) {
        seneca.log.warn('invalid email', email);
        return respond(null, {
          message: 'invalid email'
        });
      }
      return account.identify({
        email: email
      }, function(error, acc) {
        var password;
        if (acc) {
          seneca.log.warn('account already registered', acc.email);
          return respond(null, {
            message: 'account already registered'
          });
        } else {
          password = args.password;
          if (!password) {
            seneca.log.debug('generating password');
            password = util.generate_password(password_length);
            password_generated = true;
          }
          return bcrypt.genSalt(10, function(error, salt) {
            if (error) {
              seneca.log.error('salt generation failed:', error.message);
              return respond(error, null);
            }
            return bcrypt.hash(password, salt, function(error, hash) {
              var new_account;
              if (error) {
                seneca.log.error('password hash failed:', error.message);
                return respond(error, null);
              }
              new_account = seneca.make('account');
              new_account.email = email;
              new_account.hash = hash;
              new_account.registered_at = moment().format();
              new_account.status = status;
              return new_account.save$(function(error, saved_account) {
                if (error) {
                  seneca.log.error('new account record failed:', error.message);
                  return respond(error, null);
                }
                if (saved_account) {
                  seneca.log.debug('new account saved');
                  if (password_generated) {
                    saved_account.password = password;
                  }
                  if (status === 'confirmed') {
                    return respond(null, saved_account);
                  } else {
                    seneca.log.debug('issuing the conf token...');
                    return account.issue_token({
                      account_id: saved_account.id,
                      reason: 'conf'
                    }, function(error, res) {
                      if (error) {
                        seneca.log.error('confirmation token issue failed', error.message);
                        return respond(error, null);
                      }
                      saved_account.token = res.token;
                      return respond(null, saved_account);
                    });
                  }
                }
              });
            });
          });
        }
      });
    };
    return cmd_register;
  };

}).call(this);

//# sourceMappingURL=register.js.map
