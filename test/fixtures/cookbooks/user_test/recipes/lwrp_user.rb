#
# Cookbook Name:: user_test
# Recipe:: lwrp_user
#
# Copyright (C) 2014 Brian Clark <brian@clark.zone>
#
# rubocop:disable Metrics/LineLength

node.default['user_test']['uid'] = nil

user_account 'test_user' do
  uid node['user_test']['uid'] unless node['user_test']['uid'].nil?
  gid node['user_test']['gid'] unless node['user_test']['gid'].nil?
  home node['user_test']['home'] unless node['user_test']['home'].nil?
  manage_home node['user_test']['manage_home'] unless node['user_test']['manage_home'].nil?
  shell node['user_test']['shell'] unless node['user_test']['shell'].nil?
  password node['user_test']['password'] unless node['user_test']['password'].nil?
  authorized_keys node['user_test']['authorized_keys'] unless node['user_test']['authorized_keys'].nil?
  authorized_keys_bag node['user_test']['authorized_keys_bag'] unless node['user_test']['authorized_keys_bag'].nil?
  sudo node['user_test']['sudo'] unless node['user_test']['sudo'].nil?
  action node['user_test']['action'] unless node['user_test']['action'].nil?
  notifies :write, 'log[log]', :immediately
end

log 'log' do
  action :nothing
  level :info
  message "I've been notified"
end
