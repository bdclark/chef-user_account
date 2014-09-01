#
# Cookbook Name:: user_test
# Recipe:: users
#
# Copyright (C) 2014 Brian Clark <brian@clark.zone>
#

user_account 'frodo'

user_account 'bilbo' do
  gid 100
  action :create
  authorized_keys ['ssh-rsa AAAAkey', 'bilbo']
  authorized_keys_bag 'sshkeys'
  notifies :write, 'log[log]', :immediately
end

log 'log' do
  action :nothing
  message 'This is a notification that bilbo was created'
end

user_account 'legolas' do
  authorized_keys ['elves']
  authorized_keys_bag 'sshkeys'
end

user_account 'sauron' do
  uid 666
  home '/home/morder'
  authorized_keys ['ssh-rsa AAAAmykey', 'ssh-rsa AAAAmyotherkey']
  sudo true
end

user_account 'gandalf' do
  comment 'Gandalf the Grey'
  home '/dev/null'
  gid 'wizards'
  shell '/bin/false'
  password '$1$xz0FtiKR$cW9e22mUbM4Hg23q5pjFd/'
  authorized_keys 'ssh-rsa AAAAgandalfkey'
end

user_account 'root' do
  authorized_keys 'ssh-ed25519 AAAAroots_authorized_key'
end

user_account 'gollum' do
  action :lock
  authorized_keys 'asdf'
end
