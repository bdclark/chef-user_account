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
  ssh_keys ['ssh-rsa AAAAkey', 'bilbo']
  ssh_keys_bag 'sshkeys'
  notifies :write, 'log[log]', :immediately
end

log 'log' do
  action :nothing
  message 'This is a notification that bilbo was created'
end

user_account 'legolas' do
  ssh_keys ['elves']
  ssh_keys_bag 'sshkeys'
end

user_account 'sauron' do
  uid 666
  home '/home/morder'
  ssh_keys ['ssh-rsa AAAAmykey', 'ssh-rsa AAAAmyotherkey']
  sudo true
end

user_account 'gandalf' do
  comment 'Gandalf the Grey'
  home '/dev/null'
  gid 'wizards'
  shell '/bin/false'
  password '$1$xz0FtiKR$cW9e22mUbM4Hg23q5pjFd/'
  ssh_keys 'ssh-rsa AAAAgandalfkey'
  sudo true
  sudo_nopasswd false
end

user_account 'root' do
  ssh_keys 'ssh-ed25519 AAAAroots_authorized_key'
end

user_account 'gollum' do
  action [:create, :remove]
  ssh_keys 'asdf'
end
