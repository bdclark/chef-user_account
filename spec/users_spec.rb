require 'spec_helper'

recipe = 'user_account::users'

describe 'users recipe' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['user_account']['users']['bclark']['uid'] = 888
      node.set['user_account']['users']['bclark']['home'] = '/home/test_user'
      node.set['user_account']['users']['bclark']['shell'] = '/bin/false'
      node.set['user_account']['users']['bclark']['password'] = 'secret'
      node.set['user_account']['users']['bclark']['sudo'] = true
      node.set['user_account']['users']['bclark']['sudo_nopasswd'] = false
      node.set['user_account']['users']['bclark']['ssh_keys'] =
        ['ssh-rsa AAAAmykey']
      node.set['user_account']['users']['bclark']['ssh_keys_bag'] = 'sshkeys'
    end.converge(recipe)
  end

  let(:getpwnam) do
    double('pwnam', uid: 888, gid: 999, dir: '/home/test_user')
  end

  before { allow(Etc).to receive(:getpwnam).and_return(getpwnam) }

  it 'creates user with specified attributes' do
    expect(chef_run).to create_user_account('bclark').with(
      uid: 888,
      home: '/home/test_user',
      shell: '/bin/false',
      password: 'secret',
      sudo: true,
      sudo_nopasswd: false,
      ssh_keys: ['ssh-rsa AAAAmykey'],
      ssh_keys_bag: 'sshkeys')
  end

  it 'removes user if action is :remove' do
    chef_run.node.set['user_account']['users']['bclark']['action'] = :remove
    chef_run.converge(recipe)
    expect(chef_run).to remove_user_account('bclark')
  end
end
