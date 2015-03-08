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

[:create, :modify, :manage, :lock, :unlock].each do |a|
  action a do
    assert_user_exists(a) unless [:create, :manage].include?(a)
    user_resource(a)
    sudo_resource(:install)
    ssh_file_resources
  end
end

action :remove do
  user_resource(:remove)
  sudo_resource(:remove)
end

def user_resource(exec_action)
  user new_resource.username do
    uid new_resource.uid
    gid ensure_user_group if new_resource.gid && exec_action != :remove
    comment new_resource.comment
    shell new_resource.shell
    password new_resource.password
    supports manage_home: if new_resource.manage_home.nil?
                            node['user_account']['manage_home']
                          else
                            new_resource.manage_home
                          end
    home home_directory
    action :nothing
  end.run_action(exec_action)
end

def sudo_resource(exec_action)
  exec_action = :remove unless new_resource.sudo && exec_action == :install
  sudo new_resource.username do
    user new_resource.username
    nopasswd new_resource.sudo_nopasswd
    action exec_action
  end
end

def user_group
  Etc.getpwnam(new_resource.username).gid
end

def ssh_file_resources
  keys = authorized_keys
  home = home_directory
  if keys
    if ::File.directory?(home)
      directory "#{home}/.ssh" do
        owner new_resource.username
        group user_group
        mode '0700'
      end

      template "#{home}/.ssh/authorized_keys" do
        source 'authorized_keys.erb'
        cookbook new_resource.cookbook
        owner new_resource.username
        group user_group
        mode '0600'
        variables ssh_keys: keys
      end
    else
      msg = "user_account[#{new_resource.username}] unable to manage ssh "\
        "files for user, home directory '#{home}' does not exist"
      Chef::Log.warn(msg) unless ::File.directory?(home)
    end
  elsif manage_ssh_files? == true
    file "#{home}/.ssh/authorized_keys" do
      action :delete
      only_if { ::File.exist?("#{home}/.ssh/authorized_keys") }
    end
  end
end

def manage_ssh_files?
  new_resource.manage_ssh_files unless new_resource.manage_ssh_files.nil?
  node['user_account']['manage_ssh_files']
end

def authorized_keys
  keys = []
  Array(new_resource.ssh_keys).each do |item|
    if valid_public_key?(item)
      keys << item
    else
      key_bag = new_resource.ssh_keys_bag
      msg = "user_account[#{new_resource.username}] authorized_key '#{item}'"\
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
            Chef::Log.warn("user_account[#{new_resource.username}] "\
              "value from data bag '#{key_bag}' item '#{item}' "\
              'not a valid public SSH key - skipping key')
          end
        end
      else
        Chef::Log.warn("user_account[#{new_resource.username}] unable to find "\
          "ssh_keys in data bag '#{key_bag}' item '#{item}' - skipping key")
      end
    end
  end
  keys.empty? ? nil : keys
end

def valid_public_key?(key)
  key =~ /^(ssh-(dss|rsa|ed25519)|ecdsa-sha2-\w+) AAAA/ ? true : false
end

# The user block will fail if the group does not yet exist.
# See the -g option limitations in man 8 useradd for an explanation.
# This should correct that without breaking functionality.
def ensure_user_group
  if new_resource.gid.is_a?(String)
    group_name = new_resource.gid
    Etc.getgrnam(new_resource.gid).gid
  else
    group_name = new_resource.username
    Etc.getgrgid(new_resource.gid).gid
  end
rescue ArgumentError
  Chef::Log.info(
    "user_account[#{new_resource.username}] creating group #{group_name}")
  group group_name do
    gid new_resource.gid if new_resource.gid.is_a?(Integer)
  end.run_action(:create)
  Etc.getgrnam(group_name).gid
end

def home_directory
  return new_resource.home if new_resource.home
  Etc.getpwnam(new_resource.username).dir
rescue ArgumentError
  return ::File.join(node['user_account']['home_root'], new_resource.username)
end

def assert_user_exists(exec_action)
  true if Etc.getpwnam(new_resource.username)
rescue ArgumentError
  raise "Cannot #{exec_action} user #{new_resource.username} - does not exist!"
end
