#
# Cookbook Name:: user_account
# Resource:: default
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

actions :create, :remove, :modify, :manage, :lock, :unlock
default_action :create

attribute :username, kind_of: String, name_attribute: true
attribute :comment, kind_of: String
attribute :uid, kind_of: [String, Integer]
attribute :gid, kind_of: [String, Integer]
attribute :home, kind_of: String
attribute :manage_home, kind_of: [TrueClass, FalseClass], default: nil
attribute :shell, kind_of: String
attribute :password, kind_of: String
attribute :ssh_keys, kind_of: [Array, String]
attribute :ssh_keys_bag, kind_of: String
attribute :cookbook, kind_of: String, default: 'user_account'
attribute :sudo, kind_of: [TrueClass, FalseClass], default: false
attribute :sudo_nopasswd, kind_of: [TrueClass, FalseClass], default: true
