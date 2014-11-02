#
# Cookbook Name:: user_account
# Provider:: default
#
# Copyright (C) 2014 Brian Clark <brian@clark.zone>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/data_bag'

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

def load_current_resource
  @username = new_resource.username
end

action :create do
  user_resource(:create)
  sudo_resource(@username, :install)
  manage_ssh_files
end

action :modify do
  assert_user_exists(:modify)
  user_resource(:modify)
  sudo_resource(@username, :install)
  manage_ssh_files
end

action :manage do
  if user_exists?
    user_resource(:manage)
    sudo_resource(@username, :install)
    manage_ssh_files
  else
    msg = "user_account[#{@username}] unable to manage user - does not exist!"
    Chef::Log.info(msg)
  end
end

action :lock do
  assert_user_exists(:lock)
  user_resource(:lock)
  sudo_resource(@username, :install)
  manage_ssh_files
end

action :unlock do
  assert_user_exists(:unlock)
  user_resource(:unlock)
  sudo_resource(@username, :install)
  manage_ssh_files
end

action :remove do
  user_resource(:remove)
  sudo_resource(@username, :remove)
end

private

def user_resource(exec_action)
  group_id = ensure_user_group if new_resource.gid && exec_action != :remove
  home = home_directory
  manage_home = if new_resource.manage_home.nil?
                  node['user_account']['manage_home']
                else
                  new_resource.manage_home
                end
  user @username do
    uid new_resource.uid if new_resource.uid
    gid group_id if group_id
    comment new_resource.comment if new_resource.comment
    shell new_resource.shell if new_resource.shell
    password new_resource.password if new_resource.password
    supports manage_home: manage_home
    home home
    action :nothing
  end.run_action(exec_action)
end

def sudo_resource(user, exec_action)
  exec_action = :remove unless new_resource.sudo && exec_action == :install
  sudo user do
    user user
    nopasswd new_resource.sudo_nopasswd
    action exec_action
  end
end

def manage_ssh_files
  home = home_directory
  if ::File.directory?(home)
    user_group = Etc.getpwnam(@username).gid
    ssh_directory(home, @username, user_group)
    authorized_keys_file(home, @username, user_group)
  elsif new_resource.ssh_keys && !new_resource.ssh_keys.empty?
    msg = "user_account[#{@username}] unable to manage ssh files for user"
    Chef::Log.warn(msg)
  end
end

def authorized_keys_file(homedir, user, group)
  keys = authorized_keys
  if keys
    template "#{homedir}/.ssh/authorized_keys" do
      source 'authorized_keys.erb'
      cookbook new_resource.cookbook
      owner user
      group group
      mode '0600'
      variables ssh_keys: keys
    end
  else
    file "#{homedir}/.ssh/authorized_keys" do
      action :delete
    end
  end
end

def authorized_keys
  keys = []
  Array(new_resource.ssh_keys).each do |item|
    if valid_public_key?(item)
      keys << item
    else
      key_bag = new_resource.ssh_keys_bag
      msg = "user_account[#{@username}] authorized_key '#{item}'"\
        ' not a valid public SSH key'
      if key_bag.nil?  || key_bag.empty?
        msg << ' and ssh_keys_bag not specified - skipping key'
        Chef::Log.warn(msg)
        next
      end
      unless Chef::DataBag.list.key?(key_bag)
        msg << " and data bag '#{key_bag}' not found - skipping key"
        Chef::Log.warn(msg)
        next
      end
      user = data_bag_item(key_bag, item)
      if user['ssh_keys']
        Array(user['ssh_keys']).each do |key|
          if valid_public_key?(key)
            keys << key
          else
            msg = "user_account[#{@username}] value from data bag '#{key_bag}'"\
              " with id '#{item}' not a valid public SSH key - skipping key"
            Chef::Log.warn(msg)
          end
        end
      else
        msg = "user_account[#{@username}] unable to find ssh_keys from"\
          " data bag '#{key_bag}' with id '#{item}' - skipping key"
        Chef::Log.info(msg)
      end
    end
  end
  keys.empty? ? nil : keys
end

def valid_public_key?(key)
  key =~ /^(ssh-(dss|rsa|ed25519)|ecdsa-sha2-\w+) AAAA/ ? true : false
end

def ssh_directory(homedir, user, group)
  return unless new_resource.ssh_keys
  directory "#{homedir}/.ssh" do
    owner user
    group group
    mode '0700'
  end
end

# The user block will fail if the group does not yet exist.
# See the -g option limitations in man 8 useradd for an explanation.
# This should correct that without breaking functionality.
def ensure_user_group
  if new_resource.gid.is_a?(String)
    group_name = new_resource.gid
    Etc.getgrnam(new_resource.gid).gid
  else
    group_name = @username
    Etc.getgrgid(new_resource.gid).gid
  end
rescue ArgumentError
  Chef::Log.info("user_account[#{@username}] creating group #{group_name}")
  group group_name do
    gid new_resource.gid if new_resource.gid.is_a?(Integer)
  end.run_action(:create)
  Etc.getgrnam(group_name).gid
end

def home_directory
  return new_resource.home if new_resource.home
  # get /etc/passwd home if user exists
  Etc.getpwnam(@username).dir
rescue ArgumentError
  return ::File.join(node['user_account']['home_root'], @username)
end

def user_exists?
  true if Etc.getpwnam(@username)
rescue ArgumentError
  false
end

def assert_user_exists(exec_action)
  return true if user_exists?
  fail "Cannot #{exec_action} user #{@username} - does not exist!"
end
