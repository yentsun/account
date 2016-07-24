0.8.0
-----
- [ ] camelCase parameters (opposite to under_score)
- [ ] basic documentation
- [x] coverage 100%
- [ ] system errors, no silencing


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
