require 'serverspec'

set :backend, :exec

describe user('frodo') do
  it { should exist }
  it { should belong_to_group 'frodo' }
  it { should have_home_directory '/home/frodo' }
end

describe user('bilbo') do
  it { should exist }
  it { should belong_to_group 100 }
  it { should have_home_directory '/home/bilbo' }
  it { should have_authorized_key 'ssh-rsa AAAAkey' }
  it { should have_authorized_key 'ssh-rsa AAAAdatabagpublickey' }
end

describe file('/home/bilbo/.ssh') do
  it { should be_directory }
  it { should be_mode 700 }
  it { be_owned_by 'bilbo' }
end

describe file('/home/bilbo/.ssh/authorized_keys') do
  it { should be_file }
  it { should be_owned_by 'bilbo' }
  it { should be_mode 600 }
end

describe user('legolas') do
  it { should exist }
  it { should have_authorized_key 'ssh-rsa AAAAelfpublickey1' }
  it { should have_authorized_key 'ssh-rsa AAAAelfpublickey2' }
  it { should_not have_authorized_key 'badelfpublickey' }
end

describe user('sauron') do
  it { should exist }
  it { should have_uid 666 }
  it { should have_home_directory '/home/morder' }
  it { should belong_to_group 'sauron' }
  it { should have_authorized_key 'ssh-rsa AAAAmykey' }
  it { should have_authorized_key 'ssh-rsa AAAAmyotherkey' }
end

describe file('/etc/sudoers.d/sauron') do
  it { should be_file }
  its(:content) { should match(/sauron ALL=\(ALL\) NOPASSWD:ALL/) }
  it { should be_owned_by 'root' }
  it { should be_mode 440 }
end

describe user('gandalf') do
  it { should exist }
  it { should have_home_directory '/dev/null' }
  # it { should belong_to_primary_group 'wizards' }
  it { should belong_to_group 'wizards' }
  it { should have_login_shell '/bin/false' }
  it { should_not have_authorized_key 'ssh-rsa AAAAgandalfkey' }
end

describe user('root') do
  it { should have_authorized_key 'ssh-ed25519 AAAAroots_authorized_key' }
end

describe user('gollum') do
  it { should_not exist }
end

describe file('/home/gollum') do
  it { should_not be_file }
  it { should_not be_directory }
end
