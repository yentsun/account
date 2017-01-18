- [x] added ability to get user by email

0.9.0
-----
- [x] added `role:account,cmd:count` pattern
- [ ] camelCase parameters (opposite to under_score)
- [ ] basic documentation
- [ ] coverage 100%
- [ ] system errors, no silencing


0.8.9
-----
- [x] added `role:account,cmd:count` pattern


0.8.8
-----
- [x] added `role:account,cmd:list` pattern


0.8.7
-----
 - [x] `authenticate` returns null if check fails


0.8.5
-----
 - [x] `authenticate` returns user if check passes


0.8.4
-----
 - [x] fixed weird bug with condition check
 
 
 0.8.3
-----
 - [x] compare new account status to existing one


0.8.2
-----
 - [x] return fields updated by `account.update` command


0.8.0
-----
 - [x] removed `account.authorize` command with ACL features


0.7.26
------
- [x] fixed `zone` and `base` options handling


0.7.25
------
- [x] added `zone` and `base` options to `seneca.make`


0.7.24
------
- [x] fixed get user from storage failure scenario


0.7.23
------
- [x] added `aud` to acl user group check


0.7.22
------
- [x] renamed `reason` parameter in JWT payload to `aud`


0.7.21
------
- [x] removed pattern pinning from commands


0.7.19
------
- recognize unidentified user as `anonymous` @ `authorize` cmd


0.7.17
------
- authorize with accountId


0.7.9
-----
- 'loose' payload @ `issue token`


0.7.8
-----
- `confirm` command transformed to `update` command


0.7.7
-----
- `register` command accepts `status` value


0.7.6
-----
- add `status` field to the account object
- add `confirm` command
- rename `login` to `issue_token`
- add `verify` command to abstract token tasks


0.7.5
-----
- failure messages


0.7.2
-----
- introduce internal id (instead of email-as-id)


0.7.0
-----
- stable state
- coverage 100%
