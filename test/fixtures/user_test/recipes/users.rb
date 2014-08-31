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
  notifies :write, 'log[log]', :immediately
end

log 'log' do
  action :nothing
  message 'This is a notification'
end

user_account 'sauron' do
  uid 666
  home '/home/morder'
  authorized_keys %w(abcdef 0123456789)
  sudo true
end

user_account 'gandalf' do
  comment 'Gandalf the Grey'
  home '/dev/null'
  gid 'wizards'
  shell '/bin/false'
  password '$1$xz0FtiKR$cW9e22mUbM4Hg23q5pjFd/'
end

user_account 'root' do
  authorized_keys 'roots_authorized_key'
end

user_account 'gollum' do
  action :lock
  authorized_keys 'asdf'
end

user_account 'locked_user' do
  password '$1$xz0FtiKR$cW9e22mUbM4Hg23q5pjFd/'
end

user_account 'locked_user' do
  sudo true
  authorized_keys 'mykey'
  shell '/bin/false'
  action :lock
end
