# <a name='title'></a> Chef user_account Cookbook

[![Build Status](https://travis-ci.org/bdclark/chef-user_account.svg)](https://travis-ci.org/bdclark/chef-user_account)

## <a name='description'></a> Description
The `user_account` cookbook configures user accounts, SSH authorized_keys,
user sudo privileges, etc.

Currently, it doesn't manage groups, it doesn't create users from data bags,
etc. and (currently) has zero functional recipes. Additional functionality is
being considered; in the meantime that's what wrapper cookbooks are for (example forthcoming).

The LWRP in this cookbook was heavily inspired by the [user](https://github.com/fnichol/chef-user)
cookbook by @fnichol and the Opscode [users](https://github.com/sethvargo-cookbooks/users) cookbook
currently maintained by @sethvargo.

## <a name='requirements'></a>  Requirements

### <a name="requirements-chef"></a> Chef

Tested on 11.X, but should be pretty compatible (nothing fancy here).

### <a name="requirements-platform"></a> Platform

The following platforms have been tested with this cookbook, however it will likely
support more:

* ubuntu
* centos
* amazon

### <a name="requirements-cookbooks"></a> Cookbooks

+ [sudo cookbook](https://github.com/opscode-cookbooks/sudo) (for setting user-specific
  sudo privileges)

## <a name='recipes'></a> Recipes
### <a name='recipe-default'></a> default
This recipe is a no-op and does nothing (and never will).

## <a name='attributes'></a> Attributes

#### home_root
The default parent path of a user's home directory. Can be overridden by each
resource.  Defaults to `/Users` for OSX, otherwise `/home`.

#### manage_home
Whether of not to manage the home directory of a user by default. Can be
overridden by each resource. Default is `true`.

## <a name='lwrps'></a> Resources and Providers
### <a name='lwrp-ua'></a> user_account
The `user_account` LWRP manages users, their SSH authorized_keys files, and
per-user sudo privileges.

### <a name='lwrp-ua-actions'></a> Actions

Action    | Description
----------|---------------------------------------------
`:create` | **Default action**: create user account
`:remove` | remove user (and remove from /etc/sudoers.d even if `sudo` attribute is true)
`:modify` | modify user account (raises error if user does not exist)
`:lock`   | lock user password (raises error if user does not exist)
`:unlock` | unlock user password (raises error if user does not exist)
`:manage` | manage user account (does nothing if user does not exist)

### <a name='lwrp-ua-attributes'></a> Attributes

Attribute    | Description                                    | Default
-------------|------------------------------------------------|--------
username     | **Name attribute**: username (required)        | `nil`
comment      | comment passed to chef user resource           | `nil`
uid          | uid passed to chef user resource               | `nil`
gid          | gid passed to chef user resource (see below)   | `nil`
home         | home directory passed to chef user resource    | `nil`
manage_home  | whether to manage user's home directory        | `true`
shell        | shell passed to chef user resource             | `nil`
password     | password passed to chef user resource          | `nil`
ssh_keys     | string/array of public SSH keys, and/or data bag item(s) to lookup | `nil`
ssh_keys_bag | optional data bag name holding public SSH keys | `nil`
cookbook     | source of template for authorized_keys file    | `user_account`
sudo         | whether to enable user sudo in /etc/sudoers.d  | `false`

### <a name='lwrp-ua-description'></a> Description
If the `gid` attribute is set, the LWRP will create the group if it doesn't
already exist (otherwise the underlying Chef user resource would fail). If `gid`
is numeric, the new group will be named after the user. If `gid` is a string,
the new group name will be the value of `gid`.

User-specific sudo rights can be given by setting `sudo` to `true`.
This attribute requires the node's sudo config to have `#includedir` set properly.
See the [sudo cookbook](https://github.com/opscode-cookbooks/sudo) for details.

SSH authorized_key(s) can be set by passing a string or array to `ssh_keys`.
Only valid keys will be added. If an invalid key is provided, it will
assume the value is a data bag item and attempt to retrieve public key(s) from
the data bag specified in `ssh_keys_bag`. `ssh_keys` can be populated
with multiple public keys as well multiple data bag items. If a data bag is used,
it must at least contain `id` and `ssh_keys` keys. For example:

```json
{
  "id": "username",
  "ssh_keys": "ssh-rsa AAAA..."
}
```
```json
{
  "id": "username",
  "ssh_keys": [
    "ssh-rsa AAAA...",
    "ssh-ed25519 AAAA..."
  ]
}
```
Public SSH keys specified with `authorized_keys` will be created in
`~/.ssh/authorized_keys` as long as home directory is valid (e.g. not /dev/null).

### <a name='lwrp-ua-examples'></a> Usage and Examples
Using defaults, create user w/ no password and managed home directory
(`/home/bbaggins` by default, or `/Users/bbaggins` on OSX).
```ruby
user_account 'bbaggins'
```
Create user with specific attributes. User's primary group is `hobbits`, and will
be created if not already present. User will have sudo rights via an entry
in `/etc/sudoers.d` and two public SSH keys in `/home/shire/.ssh/authorized_keys`.
```ruby
user_account 'sgamgee' do
  comment 'Samwise Gamgee'
  gid 'hobbits'
  home '/home/shire'
  ssh_keys ['ssh-rsa AAAAfoo...', 'ssh-rsa AAAAbar...']
  sudo true
  action :create
end
```
Create user with primary group id `666`. If group not already present, it will be
called `sauron`.
```ruby
user_account 'sauron' do
  gid 666
end
```
Modify existing user, adding valid SSH keys from data bag item `elves` in
data bag `sshkeys` to `~/legolas/.ssh/authorized_keys`.
```ruby
user_account 'legolas' do
  ssh_keys 'elves'
  ssh_keys_bag 'sshkeys'
  action :modify
end
```

### <a name='lwrp-ua-notes'></a> Misc. Notes and Considerations
+ The LWRP does not handle password encryption for the `password` attribute.
There are multiple solutions/tools available to generate valid encrypted passwords.
See the [chef docs](https://docs.getchef.com/resource_user.html#password-shadow-hash)
for details.
+ Keep in mind the `:lock` and `:unlock` actions only affect a user's
password. Locking a password does not necessarily block a user from SSH access,
for example if password-less SSH is enabled and authorized_keys exists for the user.

## <a name='license'></a> License and Author
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
