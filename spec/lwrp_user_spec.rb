require 'spec_helper'

recipe = 'user_test::lwrp_user'
# auth_key_bag = {
#   id: 'bob',
#   authorized_keys: ['ssh-rsa AAAAmykey']
# }

describe 'user_account lwrp' do
  let(:chef_run) do
    ChefSpec::Runner.new(step_into: ['user_account'])
  end
  let(:getpwnam) do
    double('pwnam', uid: 888, gid: 999, dir: '/home/test_user')
  end

  context 'with no attributes' do
    before(:each) do
      allow(Etc).to receive(:getpwnam).and_return(getpwnam)
      chef_run.converge(recipe)
    end

    it 'creates a user with username as named attribute' do
      expect(chef_run).to create_user('test_user')
        .with(username: 'test_user')
    end
    it 'manages home directory' do
      expect(chef_run).to create_user('test_user').with(
        supports: { manage_home: true })
    end
    it 'removes sudo access' do
      expect(chef_run).to remove_sudo('test_user')
    end
    it 'does not create a group' do
      expect(chef_run).not_to create_group('test_user')
    end
    it 'does not create .ssh dir' do
      expect(chef_run).not_to create_directory('/home/test_user/.ssh')
    end
    it 'does not create authorized_keys file' do
      expect(chef_run).not_to create_template(
        '/home/test_user/.ssh/authorized_keys')
    end
  end

  context 'when creating a user with attributes' do
    before do
      chef_run.node.set['user_test']['uid'] = 888
      chef_run.node.set['user_test']['home'] = '/home/test_user'
      chef_run.node.set['user_test']['shell'] = '/bin/false'
      chef_run.node.set['user_test']['password'] = 'secret'
      chef_run.node.set['user_test']['sudo'] = true
    end
    before(:each) do
      allow(Etc).to receive(:getpwnam).and_return(getpwnam)
      chef_run.converge(recipe)
    end
    it 'assigns the specified username' do
      expect(chef_run).to create_user('test_user').with(username: 'test_user')
    end
    it 'assigns the specified uid' do
      expect(chef_run).to create_user('test_user').with(uid: 888)
    end
    it 'assigns the specified home' do
      expect(chef_run).to create_user('test_user')
        .with(home: '/home/test_user')
    end
    it 'manages user home directory' do
      expect(chef_run).to create_user('test_user').with(
        supports: { manage_home: true })
    end
    it 'assigns the specified shell' do
      expect(chef_run).to create_user('test_user').with(shell: '/bin/false')
    end
    it 'assigns the specified password' do
      expect(chef_run).to create_user('test_user').with(password: 'secret')
    end

    let(:etc_group) { double('group', gid: 888, name: 'mygroup') }

    context 'when gid attribute is numeric' do
      before { chef_run.node.set['user_test']['gid'] = 888 }
      it 'creates group if it did not exist' do
        # Fail group lookup
        allow(Etc).to receive(:getgrgid).with(888).and_raise(ArgumentError)
        # Gets group named after username after creating group
        allow(Etc).to receive(:getgrnam).with('test_user')
          .and_return(double(gid: 888, name: 'test_user'))
        chef_run.converge(recipe)
        expect(chef_run).to create_group('test_user').with(gid: 888)
      end
      it 'does not create group if already exists' do
        allow(Etc).to receive(:getgrgid).and_return(etc_group)
        chef_run.converge(recipe)
        expect(chef_run).not_to create_group('test_user')
      end
    end

    context 'when gid attribute is string' do
      before { chef_run.node.set['user_test']['gid'] = 'mygroup' }
      it 'creates group if it does not exist' do
        # Fail group lookup
        expect(Etc).to receive(:getgrnam).with('mygroup')
          .and_raise(ArgumentError)
        # Gets group name after creating group
        allow(Etc).to receive(:getgrnam).and_return(etc_group)
        chef_run.converge(recipe)
        expect(chef_run).to create_group('mygroup')
      end
      it 'does not create group if already exists' do
        allow(Etc).to receive(:getgrnam).and_return(etc_group)
        chef_run.converge(recipe)
        expect(chef_run).not_to create_group('mygroup')
      end
    end
  end

  context 'with a non-existing user' do
    [:lock, :unlock, :manage, :modify].each do |action|
      context "when action is #{action}" do
        before do
          chef_run.node.set['user_test']['action'] = action
          chef_run.node.set['user_test']['home'] = '/home/tu'
          chef_run.node.set['user_test']['authorized_keys'] =
            ['ssh-rsa AAAAmykey', 'ssh-rsa AAAAyourkey']
          expect(Etc).to receive(:getpwnam).and_raise(ArgumentError)
          expect(Chef::Log).to receive(:warn).with(/user does not exist/)
          chef_run.converge(recipe)
        end
        it 'does not perform any user action' do
          expect(chef_run).not_to create_user('test_user')
          expect(chef_run).not_to remove_user('test_user')
          expect(chef_run).not_to lock_user('test_user')
          expect(chef_run).not_to unlock_user('test_user')
          expect(chef_run).not_to modify_user('test_user')
          expect(chef_run).not_to manage_user('test_user')
        end
        it 'does not perform sudo action' do
          expect(chef_run).not_to remove_sudo('test_user')
          expect(chef_run).not_to install_sudo('test_user')
        end
        it 'does not create .ssh dir' do
          expect(chef_run).not_to create_directory('/home/tu/.ssh')
        end
        it 'does not create authorized_keys' do
          expect(chef_run)
            .not_to create_template('/home/tu/.ssh/authorized_keys')
        end
        it 'does not delete authorized_keys' do
          expect(chef_run)
            .not_to delete_file('/home/tu/.ssh/authorized_keys')
        end
      end
    end

    context 'when action is remove' do
      it 'removes user' do
        chef_run.node.set['user_test']['action'] = :remove
        chef_run.converge(recipe)
        expect(chef_run).to remove_user('test_user')
      end
      it 'removes sudo even if sudo true' do
        chef_run.node.set['user_test']['sudo'] = true
        chef_run.node.set['user_test']['action'] = :remove
        chef_run.converge(recipe)
        expect(chef_run).to remove_sudo('test_user')
      end
    end
  end

  context 'with a pre-existing user' do
    let(:etc) { double('etc', gid: 999, dir: '/home/tu') }
    [:create, :lock, :unlock, :manage, :modify].each do |action|
      context "when action is #{action}" do
        before do
          chef_run.node.set['user_test']['action'] = action
          chef_run.node.set['user_test']['home'] = '/home/tu'
          chef_run.node.set['user_test']['authorized_keys'] =
            ['ssh-rsa AAAAmykey', 'ssh-rsa AAAAyourkey']
          chef_run.node.set['user_test']['sudo'] = true
          allow(Etc).to receive(:getpwnam).and_return(etc)
          chef_run.converge(recipe)
        end
        it 'performs correct user action' do
          case action
          when :create
            expect(chef_run).to create_user('test_user')
          when :lock
            expect(chef_run).to lock_user('test_user')
          when :unlock
            expect(chef_run).to unlock_user('test_user')
          when :modify
            expect(chef_run).to modify_user('test_user')
          when :manage
            expect(chef_run).to manage_user('test_user')
          end
        end

        context 'with sudo attribute' do
          it 'installs sudo if true' do
            expect(chef_run).to install_sudo('test_user')
          end
          it 'removes sudo if false' do
            chef_run.node.set['user_test']['sudo'] = false
            chef_run.converge(recipe)
            expect(chef_run).to remove_sudo('test_user')
          end
        end

        context 'when authorized_keys attribute set' do
          it 'creates .ssh dir' do
            expect(chef_run).to create_directory('/home/tu/.ssh')
          end
          it 'creates authorized_keys from template' do
            expect(chef_run).to create_template(
              '/home/tu/.ssh/authorized_keys')
          end
        end

        context 'when authorized_keys not set' do
          before do
            chef_run.node.set['user_test']['authorized_keys'] = nil
            allow(Etc).to receive(:getpwnam).and_return(etc)
            chef_run.converge(recipe)
          end
          it 'does not create .ssh dir' do
            expect(chef_run).not_to create_directory('/home/tu/.ssh')
          end
          it 'does not create authorized_keys from template' do
            expect(chef_run)
              .not_to create_template('/home/tu/.ssh/authorized_keys')
          end
          it 'deletes authorized_keys file' do
            expect(chef_run).to delete_file('/home/tu/.ssh/authorized_keys')
          end
        end

        context "when authorized_keys doesn't match a public key format" do
          before(:each) do
            chef_run.node.set['user_test']['authorized_keys'] = 'bob'
          end
          context 'when authorized_keys_bag is not set' do
            before do
              allow(Etc).to receive(:getpwnam).and_return(etc)
              stub_data_bag_item(nil, 'bob').and_return('asdf')
              chef_run.converge(recipe)
            end
            it 'does not add key' do
              expect(chef_run)
                .not_to create_template('/home/tu/.ssh/authorized_keys')
            end
          end
          # Problems with ChefSpec and data bags, need to investigate
          # context 'when authorized_keys_bag is set' do
          #   before do
          #     chef_run.node.set['user_test']['authorized_keys_bag'] = 'keys'
          #     allow(Etc).to receive(:getpwnam).and_return(etc)
          #     stub_data_bag_item('keys', 'bob').and_return(auth_key_bag)
          #     chef_run.converge(recipe)
          #   end
          #   it 'looks up item in data bag and adds key' do
          #     expect(chef_run).to create_template(
          #       '/home/tu/.ssh/authorized_keys')
          #   end
          # end
        end
      end
    end

    context 'when action is remove' do
      it 'removes user' do
        chef_run.node.set['user_test']['action'] = :remove
        chef_run.converge(recipe)
        expect(chef_run).to remove_user('test_user')
      end
      it 'removes sudo even if sudo true' do
        chef_run.node.set['user_test']['sudo'] = true
        chef_run.node.set['user_test']['action'] = :remove
        chef_run.converge(recipe)
        expect(chef_run).to remove_sudo('test_user')
      end
    end
  end

end
