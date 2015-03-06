require 'spec_helper'

recipe = 'user_test::lwrp_user'

describe 'user_account lwrp' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new.converge(recipe)
  end

  it 'performs action :create as default action' do
    expect(chef_run).to create_user_account('test_user')
  end

  it 'performs action :remove' do
    chef_run.node.set['user_test']['action'] = :remove
    chef_run.converge(recipe)
    expect(chef_run).to remove_user_account('test_user')
  end

  it 'performs action :modify' do
    chef_run.node.set['user_test']['action'] = :modify
    chef_run.converge(recipe)
    expect(chef_run).to modify_user_account('test_user')
  end

  it 'performs action :manage' do
    chef_run.node.set['user_test']['action'] = :manage
    chef_run.converge(recipe)
    expect(chef_run).to manage_user_account('test_user')
  end

  it 'performs action :lock' do
    chef_run.node.set['user_test']['action'] = :lock
    chef_run.converge(recipe)
    expect(chef_run).to lock_user_account('test_user')
  end

  it 'performs action :unlock' do
    chef_run.node.set['user_test']['action'] = :unlock
    chef_run.converge(recipe)
    expect(chef_run).to unlock_user_account('test_user')
  end
end
