#
# Recipe for developing gitlabhq software
#
# Differences with default recipe:
#  * no git sync, rely on vagrant to sync the codebase
#  * leave bundle install & gitlab:setup for the developer

# Assumes that development vagrant will use Ubuntu/Debian based base box

# Set attributes for development
node.set['gitlab']['user'] = "vagrant"
node.set['gitlab']['group'] = "vagrant"
node.set['gitlab']['home'] = "/home/vagrant/"
node.set['gitlab']['path'] = "/vagrant"
node.set['gitlab']['repos_path'] = "/home/vagrant/repositories"
node.set['gitlab']['satellites_path'] = "/home/vagrant/gitlab-satellites"
node.set['gitlab']['shell_path'] = "/home/vagrant/gitlab-shell"
node.set['gitlab']['rails_env'] = "development"
node.set['gitlab']['enable_test_db'] = true

# Let's compile latest ruby 1.9.3 from source
include_recipe "gitlab::ruby_build"

include_recipe "gitlab::debian"

# Include cookbook dependencies
%w{ git build-essential readline xml zlib python::package python::pip
redisio::install redisio::enable mysql::server mysql::ruby }.each do |requirement|
  include_recipe requirement
end

include_recipe "gitlab::gitlab_shell"

# Write config files for gitlab, puma and resque
%w{gitlab.yml puma.rb database.yml resque.yml}.each do |conf_file|
  template File.join(node['gitlab']['path'], 'config', conf_file) do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    source "#{conf_file}.erb"
  end
end

# Set ownership of repositories path
directory node['gitlab']['repos_path'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  recursive true
  mode 02770
end

# Create directory for satellites
directory node['gitlab']['satellites_path'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
end

# Configure Git global settings for git user, useful when editing via web
# Edit user.email according to what is set in gitlab.yml
bash "git config" do
  code 'git config --global user.name "GitLab" && git config --global user.email "gitlab@localhost"'
  user node['gitlab']['user']
  environment('HOME' => node['gitlab']['home'])
end

# Database
mysql_connection_info = {
  :host => "localhost",
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

# Create a mysql superuser
ruby_block "grant_db_user" do
  block do
    MysqlHelper.create_superuser(mysql_connection_info, 'gitlab', node['gitlab']['mysql_password'])
  end
end

# Manually run bundle install and rake gitlab:setup in development