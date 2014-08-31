require 'spec_helper'

describe user('frodo') do
  it { should exist }
  it { should belong_to_group 'frodo' }
  it { should have_home_directory '/home/frodo' }
end

describe user('bilbo') do
  it { should exist }
  it { should belong_to_group 100 }
  it { should have_home_directory '/home/bilbo' }
end

describe user('sauron') do
  it { should exist }
  it { should have_uid 666 }
  it { should have_home_directory '/home/morder' }
  it { should belong_to_group 'sauron' }
  it { should have_authorized_key 'abcdef' }
  it { should have_authorized_key '0123456789' }
end

describe file('/etc/sudoers.d/sauron') do
  it { should be_file }
  its(:content) { should match(/sauron  ALL=\(ALL\) NOPASSWD:ALL/) }
  it { should be_owned_by 'root' }
end

describe user('gandalf') do
  it { should exist }
  it { should have_home_directory '/dev/null' }
  it { should belong_to_primary_group 'wizards' }
  it { should have_login_shell '/bin/false' }
end

describe user('root') do
  it { should have_authorized_key 'roots_authorized_key' }
end

describe user('gollum') do
  it { should_not exist }
end

describe user('locked_user') do
  it { should exist }
  it { should have_authorized_key 'mykey' }
  it { should have_login_shell '/bin/false' }
end

describe file('/etc/sudoers.d/locked_user') do
  it { should be_file }
  its(:content) { should match(/locked_user  ALL=\(ALL\) NOPASSWD:ALL/) }
  it { should be_owned_by 'root' }
end
