#
# Cookbook Name:: user_test
# Recipe:: lwrp_user
#
# Copyright (C) 2014 Brian Clark <brian@clark.zone>
#
# rubocop:disable Style/LineLength

node.default['user_test']['uid'] = nil

user_account 'test_user' do
  uid node['user_test']['uid'] if node['user_test']['uid']
  gid node['user_test']['gid'] if node['user_test']['gid']
  home node['user_test']['home'] if node['user_test']['home']
  shell node['user_test']['shell'] if node['user_test']['shell']
  password node['user_test']['password'] if node['user_test']['password']
  authorized_keys node['user_test']['authorized_keys'] if node['user_test']['authorized_keys']
  authorized_keys_bag node['user_test']['authorized_keys_bag'] if node['user_test']['authorized_keys_bag']
  sudo node['user_test']['sudo'] if node['user_test']['sudo']
  action node['user_test']['action'] || :create
  notifies :write, 'log[log]', :immediately
end

log 'log' do
  action :nothing
  level :info
  message "I've been notified"
end
