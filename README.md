# user_account cookbook

The `user_account` cookbook is "yet another user cookbook" that configures
user accounts, including SSH authorized_keys, user sudo privileges, etc.

Currently, this cookbook does not manage groups, create users from data bags,
etc. and (currently) has no recipes. Additional functionality is being considered;
in the meantime that's what wrapper cookbooks are for (example forthcoming).

The LWRP in this cookbook was heavily inspired by the [user](https://github.com/fnichol/chef-user)
cookbook by @fnichol and the Opscode [users](https://github.com/sethvargo-cookbooks/users) cookbook
currently maintained by @sethvargo.

## Dependencies
+ [sudo cookbook](https://github.com/opscode-cookbooks/sudo) (for setting user-specific
  sudo privileges)

## user_account LWRP
The `user_account` LWRP is an opinionated extension of the Chef user
resource with some added functionality and a few differences.

### Actions

Action    | Description
----------|---------------------------------------------
`:create` | **Default action**: create user account
`:remove` | remove user (and remove from /etc/sudoers.d even if `sudo` attribute is true)
`:modify` | modify user account
`:lock`   | lock user account
`:unlock` | unlock user account
`:manage` | manage user account

### Attributes

Attribute       | Description                                   | Default
----------------|-----------------------------------------------|--------
username        | **Name attribute**: username (required)       | `nil`
comment         | comment passed to chef user resource          | `nil`
uid             | uid passed to chef user resource              | `nil`
gid             | gid passed to chef user resource (see below)  | `nil`
home            | home directory passed to chef user resource   | `nil`
shell           | shell passed to chef user resource            | `nil`
password        | password passed to chef user resource         | `nil`
authorized_keys | string or array of public SSH keys            | `nil`
cookbook        | source of template for authorized_keys file   | `user_account`
sudo            | whether to enable user sudo in /etc/sudoers.d | `false`

If the `gid` attribute is set, the LWRP will create the group if it doesn't
already exist (otherwise the underlying Chef user resource would fail). If `gid`
is numeric, the new group will be named after the user. If `gid` is a string,
the new group name will be the value of `gid`.

User-specific sudo rights can be given by setting the `sudo` attribute to `true`.
This attribute requires the node's sudo config to have `#includedir` set properly.
See the [sudo cookbook](https://github.com/opscode-cookbooks/sudo) for details.

SSH authorized_key(s) can be set by passing a string or array to the `authorized_keys`
attribute.

**Other Differences from Chef user resource**
+ Always sets `:manage_home` to `true` unless `/dev/null` is specifically set
as the user's home directory.
+ Does not raise an exception if user does not already exist when using the
`:modify`, `:lock`, `:unlock`, or `:manage` actions (however it does
log a warning).
+ Does not (currently) expose the `system` or `non-unique` attributes of the
Chef user resource.

### Examples
```ruby
# create user w/ no password and managed home dir
user_account 'bbaggins'

# create user with some custom stuff
# and a default group called 'hobbits'
user_account 'sgamgee' do
  comment 'Samwise Gamgee'
  gid 'hobbits'
  home '/home/shire'
  authorized_keys ['ssh-rsa onekey', 'ssh-rsa anotherkey']
  sudo true
  action :create
end

# create a user with custom gid
# if group doesn't exist it will be named after user
user_account 'sauron' do
  gid 666
end
```
### Misc. Considerations
+ The `:lock` action alone in this LWRP and the Chef user resource does not
necessarily block a user's access if passwordless SSH is enabled on the node.
Depending on the system, it only locks the password. To ensure access is blocked,
either `:remove` the user, or at least `:lock` the user and unset `authorized_keys`.
+ The LWRP does not handle password encryption for the `password` attribute.
There are multiple solutions/tools available to generate valid encrypted passwords.

## License and Author
- Author:: Brian Clark <brian@clark.zone> ([bdclark](https://github.com/bdclark))

```text
Copyright 2014, Brian Clark

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
