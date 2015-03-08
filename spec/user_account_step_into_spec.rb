require 'spec_helper'

recipe = 'user_test::lwrp_user'

shared_examples_for 'managing user resource' do # |user_action|
  # let(:username) { 'test_user' }
  let(:user) { chef_run.find_resource(:user, 'test_user') }

  # it "performs #{user_action} action" do
  #   expect(user.performed_actions).to include(user_action)
  # end

  context 'with no user attributes provided' do
    it 'uses name attribute' do
      expect(user.username).to eq('test_user')
    end

    it 'manages home directory' do
      expect(user.supports).to eq(manage_home: true)
    end
  end

  context 'when user attributes provided' do
    # let(:username) { 'myuser' }
    let(:shell) { '/my/shell' }
    let(:password) { 'mypass' }
    let(:uid) { 2020 }
    let(:home) { '/my/home' }
    let(:password) { 'secret1234' }
    let(:manage_home) { false }

    # it 'sets specified username' do
    #   expect(user.username).to eq('myuser')
    # end

    it 'sets specified shell' do
      expect(user.shell).to eq('/my/shell')
    end

    it 'sets specified uid' do
      expect(user.uid).to eq(2020)
    end

    it 'sets specified home dir' do
      expect(user.home).to eq('/my/home')
    end

    it 'sets specified password' do
      expect(user.password). to eq('secret1234')
    end

    it 'sets specified manage_home' do
      expect(user.supports).to eq(manage_home: false)
    end
  end
end

shared_examples_for 'managing group' do
  let(:username) { 'test_user' }
  let(:user) { chef_run.find_resource(:user, username) }

  context 'when gid not provided' do
    it 'does not set gid in user resource' do
      expect(user.gid).to eq(nil)
    end
  end

  context 'when gid provided' do
    let(:gid) { 888 }
    let(:etc_group) { double('group', gid: 888, name: 'mygroup') }

    context 'with integer gid' do
      it 'creates group if does not exist' do
        expect(Etc).to receive(:getgrgid).with(gid).and_raise(ArgumentError)
        expect(Etc).to receive(:getgrnam).and_return(etc_group)
        expect(chef_run).to create_group('test_user').with(gid: 888)
      end

      it 'does not create group if already exists' do
        allow(Etc).to receive(:getgrgid).with(gid).and_return(etc_group)
        expect(chef_run).not_to create_group('test_user')
        expect(chef_run).not_to create_group('mygroup')
        expect(chef_run).not_to create_group(888)
      end
    end

    context 'with string gid' do
      let(:gid) { 'mygroup' }

      it 'creates group if does not exist' do
        expect(Etc).to receive(:getgrnam).with(gid).and_raise(ArgumentError)
        expect(Etc).to receive(:getgrnam).and_return(etc_group)
        expect(chef_run).to create_group('mygroup')
      end

      it 'does not create group if already exists' do
        allow(Etc).to receive(:getgrnam).with(gid).and_return(etc_group)
        expect(chef_run).not_to create_group('mygroup')
        expect(chef_run).not_to create_group('test_user')
        expect(chef_run).not_to create_group(888)
      end
    end

    it 'sets gid in user resource' do
      allow(Etc).to receive(:getgrnam).and_return(etc_group)
      expect(user.gid).to eq(888)
    end
  end
end

shared_examples_for 'managing sudo' do
  context 'when sudo not specified' do
    it 'removes sudo' do
      expect(chef_run).to remove_sudo('test_user')
    end
  end

  context 'when sudo true' do
    let(:sudo) { true }

    context 'when sudo_nopasswd not specified' do
      it 'installs sudo with no_passwd true' do
        expect(chef_run).to install_sudo('test_user').with(
          user: 'test_user', nopasswd: true)
      end
    end

    context 'when sudo_nopasswd false' do
      let(:sudo_nopasswd) { false }

      it 'installs sudo with no_passwd false' do
        expect(chef_run).to install_sudo('test_user').with(
          user: 'test_user', nopasswd: false)
      end
    end

    context 'when sudo_nopasswd true' do
      let(:sudo_nopasswd) { true }

      it 'installs sudo with no_passwd true' do
        expect(chef_run).to install_sudo('test_user').with(
          user: 'test_user', nopasswd: true)
      end
    end
  end

  context 'when sudo false' do
    let(:sudo) { false }

    it 'removes sudo' do
      expect(chef_run).to remove_sudo('test_user')
    end
  end
end

# shared_examples_for 'removing sudo' do
#   it 'removes sudo' do
#     expect(chef_run).to remove_sudo('test_user')
#   end
# end

shared_examples_for 'home directory' do
  let(:username) { 'test_user' }
  let(:user) { chef_run.find_resource(:user, username) }

  context 'when home not specified' do
    context 'when user exists' do
      before { allow(Etc).to receive(:getpwnam).and_return(getpwnam) }

      it 'uses /etc/passwd home' do
        expect(user.home).to eq('/home/test_home')
      end
    end

    context 'when user does not exist' do
      before { allow(Etc).to receive(:getpwnam).and_raise(ArgumentError) }

      it 'uses cookbook home_root' do
        expect(user.home).to eq('/home/test_user')
      end
    end
  end

  context 'when home specified' do
    let(:home) { '/my/home/dir' }

    it 'uses specified home dir' do
      expect(user.home).to eq('/my/home/dir')
    end
  end
end

shared_examples_for 'setting ssh resources' do
  it 'creates .ssh directory' do
    expect(chef_run).to create_directory(ssh_dir).with(
      owner: 'test_user',
      group: 999,
      mode: '0700')
  end

  it 'creates authorized_keys template' do
    expect(chef_run).to create_template(auth_keys_file).with(
      owner: 'test_user',
      group: 999,
      mode: '0600')
  end
end

shared_examples_for 'not setting ssh resources' do
  it 'does not create .ssh directory' do
    expect(chef_run).not_to create_directory(ssh_dir)
  end

  it 'does not create authorized_keys template' do
    expect(chef_run).not_to create_template(auth_keys_file)
  end
end

shared_examples_for 'managing ssh resources' do
  context 'with no ssh key(s)' do
    let(:authorized_keys) { nil }

    it_behaves_like 'not setting ssh resources'
  end

  context 'with invalid ssh key(s)' do
    it_behaves_like 'not setting ssh resources'
  end

  context 'with valid ssh key(s)' do
  end
end

shared_examples_for 'manage_authorized_keys' do
  context 'when manage_ssh_files node attribute false' do
    it 'does not delete authorized_keys file' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(auth_keys_file).and_return(true)
      expect(chef_run).not_to delete_file(auth_keys_file)
    end
  end

  context 'when manages_ssh_files node attribute true' do
    let(:manage_ssh_files) { true }

    it 'deletes authorized_keys if file exists' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(auth_keys_file).and_return(true)
      expect(chef_run).to delete_file(auth_keys_file)
    end
  end
end

shared_examples_for 'managing ssh' do
  let(:home) { '/home/test_home' }
  let(:ssh_dir) { File.join(home, '.ssh') }
  let(:auth_keys_file) { File.join(ssh_dir, 'authorized_keys') }
  let(:getpwnam) { double('pwnam', uid: 888, gid: 999, dir: home) }

  before do
    allow(Etc).to receive(:getpwnam).and_return(getpwnam)
  end

  context 'when ssh_keys not set' do
    it_behaves_like 'not setting ssh resources'
    it_behaves_like 'manage_authorized_keys'
  end

  context 'with invalid ssh_keys' do
    let(:ssh_keys) { %w(fookey) }

    before do
      allow(File).to receive(:directory?).and_call_original
      allow(File).to receive(:directory?).with(home).and_return(true)
    end

    context 'with valid ssh_keys_bag' do
      let(:ssh_keys_bag) { 'my_keys' }

      before do
        allow(Chef::DataBag).to receive(:list).and_return(ssh_keys_bag => {})
      end

      context 'when no valid keys in bag' do
        before do
          stub_data_bag_item(ssh_keys_bag, 'fookey')
            .and_return(ssh_keys: ['bad_key'])
        end
        it 'logs warning' do
          expect(Chef::Log).to receive(:warn).with(
            /value from data bag 'my_keys' item 'fookey' not a valid public/)
          chef_run
        end

        it_behaves_like 'not setting ssh resources'
        it_behaves_like 'manage_authorized_keys'
      end

      context 'when valid keys in bag' do
        before do
          stub_data_bag_item(ssh_keys_bag, 'fookey')
            .and_return(ssh_keys: ['ssh-rsa AAAA....'])
        end

        it_behaves_like 'setting ssh resources'
      end
    end

    context 'with invalid ssh_keys_bag' do
      let(:ssh_keys_bag) { 'bad_keys_bag' }
      before { allow(Chef::DataBag).to receive(:list).and_return('barf' => {}) }

      it 'logs warning' do
        expect(Chef::Log).to receive(:warn).with(
          /not a valid public SSH key and data bag 'bad_keys_bag' not found/)
        chef_run
      end

      it_behaves_like 'not setting ssh resources'
      it_behaves_like 'manage_authorized_keys'
    end

    context 'with no ssh_keys_bag' do
      it 'logs warning' do
        expect(Chef::Log).to receive(:warn).with(
          /not a valid public SSH key and ssh_keys_bag not specified/)
        chef_run
      end

      it_behaves_like 'not setting ssh resources'
      it_behaves_like 'manage_authorized_keys'
    end
  end

  context 'with valid ssh_keys' do
    let(:ssh_keys) { ['ssh-rsa AAAA....'] }
    context 'when home dir exists' do
      before do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(home).and_return(true)
      end

      it_behaves_like 'setting ssh resources'
    end

    context 'when home dir does not exist' do
      before do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(home).and_return(false)
      end

      it_behaves_like 'not setting ssh resources'
    end
  end
end

describe 'step into user_account lwrp' do
  let(:username) { nil }
  let(:uid) { nil }
  let(:gid) { nil }
  let(:home) { nil }
  let(:manage_home) { nil }
  let(:shell) { nil }
  let(:password) { nil }
  let(:ssh_keys) { nil }
  let(:ssh_keys_bag) { nil }
  let(:sudo) { nil }
  let(:sudo_nopasswd) { nil }
  let(:action) { nil }
  let(:manage_ssh_files) { false }

  let(:getpwnam) do
    double('pwnam', uid: 888, gid: 999, dir: '/home/test_home')
  end

  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['user_account']) do |node|
      node.set['user_test']['username'] = username
      node.set['user_test']['uid'] = uid
      node.set['user_test']['gid'] = gid
      node.set['user_test']['home'] = home
      node.set['user_test']['manage_home'] = manage_home
      node.set['user_test']['shell'] = shell
      node.set['user_test']['password'] = password
      node.set['user_test']['ssh_keys'] = ssh_keys
      node.set['user_test']['ssh_keys_bag'] = ssh_keys_bag
      node.set['user_test']['sudo'] = sudo
      node.set['user_test']['sudo_nopasswd'] = sudo_nopasswd
      node.set['user_test']['action'] = action
      node.set['user_account']['manage_ssh_files'] = manage_ssh_files
    end.converge(recipe)
  end

  before do
    allow(Etc).to receive(:getpwnam).and_raise(ArgumentError)
  end

  describe ':create' do
    let(:action) { :create }

    it 'creates user' do
      expect(chef_run).to create_user('test_user')
    end

    it_behaves_like 'managing user resource'
    it_behaves_like 'managing group'
    it_behaves_like 'managing sudo'
    it_behaves_like 'managing ssh'
  end

  describe ':remove' do
    let(:action) { :remove }

    it 'removes user' do
      expect(chef_run).to remove_user('test_user')
    end

    it 'removes sudo' do
      expect(chef_run).to remove_sudo('test_user')
    end
  end

  [:modify, :manage, :lock, :unlock].each do |action|
    describe ":#{action}" do
      let(:action) { action }

      context 'with non-existing user' do
        it 'raises error' do
          expect { chef_run }.to raise_error
        end
      end
      context 'with pre-existing user' do
        before do
          allow(Etc).to receive(:getpwnam).and_return(getpwnam)
        end

        it ":#{action} user" do
          case action
          when :modify
            expect(chef_run).to modify_user('test_user')
          when :manage
            expect(chef_run).to manage_user('test_user')
          when :lock
            expect(chef_run).to lock_user('test_user')
          when :unlock
            expect(chef_run).to unlock_user('test_user')
          end
        end

        it_behaves_like 'managing user resource'
        it_behaves_like 'managing group'
        it_behaves_like 'managing sudo'
        # it_behaves_like 'managing ssh'
      end
    end
  end

  # [:create, :modify, :manage, :lock, :unlock, :remove].each do |action|
  #   describe "action #{action}" do
  #     let(:action) { action }

  #     context 'with non-existing user' do
  #       case action
  #       when :create
  #         it_behaves_like 'managing user resource', action
  #         it_behaves_like 'home directory'
  #         it_behaves_like 'managing group'
  #         it_behaves_like 'managing sudo'
  #         it_behaves_like 'managing ssh'
  #       when :remove
  #         it_behaves_like 'managing user resource', action
  #         it_behaves_like 'removing sudo'
  #       else # :modify, :manage, :lock, :unlock
  #         it 'raises error' do
  #           expect { chef_run }.to raise_error
  #         end
  #       end
  #     end

  #     context 'with pre-existing user' do
  #       before do
  #         allow(Etc).to receive(:getpwnam).and_return(getpwnam)
  #       end

  #       it_behaves_like 'managing user resource', action
  #       case action
  #       when :remove
  #         it_behaves_like 'removing sudo'
  #       else
  #         it_behaves_like 'managing group'
  #         it_behaves_like 'managing sudo'
  #         it_behaves_like 'managing ssh'
  #       end
  #     end
  #   end
  # end
end
