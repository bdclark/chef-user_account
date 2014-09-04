if defined?(ChefSpec)
  def create_user_account(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_account, :create, res_name)
  end

  def remove_user_account(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_account, :remove, res_name)
  end

  def modify_user_account(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_account, :modify, res_name)
  end

  def manage_user_account(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_account, :manage, res_name)
  end

  def lock_user_account(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_account, :lock, res_name)
  end

  def unlock_user_account(res_name)
    ChefSpec::Matchers::ResourceMatcher.new(:user_account, :unlock, res_name)
  end

end
