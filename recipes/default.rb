#
# Cookbook Name:: gitlab
# Recipe:: default
#
# Copyright (C) 2013 Andrew Fecheyr
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# This Recipe tries to follow the installation instructions at https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md
# as closely as possible (v5.0 at time of writing).

# Check if password is set
if Chef::Config[:solo]
  missing_attrs = %w{mysql_password}.select do |attr|
    node["gitlab"][attr].nil?
  end.map { |attr| "node['gitlab']['#{attr}']" }

  if !missing_attrs.empty?
    Chef::Application.fatal!("You must set #{missing_attrs.join(', ')} in chef-solo mode.")
  end
else
  # generate passwords when using chef server
  node.set_unless['gitlab']['mysql_password'] = secure_password
  node.save
end

include_recipe "apt::default"

# Include cookbook dependencies
%w{ git build-essential readline xml zlib python::package python::pip
    redisio::install redisio::enable mysql::server mysql::ruby nginx }.each do |requirement|
  include_recipe requirement
end

%w{ ruby1.9.1 ruby1.9.1-dev curl libicu-dev }.each do |pkg|
  package pkg
end

gem_package "bundler"

user node['gitlab']['user'] do
  comment   "GitLab"
  home      node['gitlab']['home']
  shell     "/bin/bash"
  supports  :manage_home => true
end

user node['gitlab']['user'] do
  action :lock
end

# Gitlab Shell
execute "clone gitlab shell" do
  command "git clone https://github.com/gitlabhq/gitlab-shell.git #{node['gitlab']['shell_path']}"
  cwd node['gitlab']['home']
  user node['gitlab']['user']
  not_if { ::File.exists?(node['gitlab']['shell_path']) }
end

template "gitlab-shell/config.yml" do
  path File.join(node['gitlab']['shell_path'], 'config.yml')
  user node['gitlab']['user']
  source "gitlab_shell_config.yml.erb"
end

execute "gitlab install" do
  command "./bin/install"
  cwd node['gitlab']['shell_path']
  user node['gitlab']['user']
  not_if { ::File.exists?(node['gitlab']['repos_path']) }
end

# Database
mysql_connection_info = {:host => "localhost",
                         :username => 'root',
                         :password => node['mysql']['server_root_password']}

# TODO: Link with notify to execute rake db:setup db:seed_fu tasks
mysql_database 'gitlabhq_production' do
  connection mysql_connection_info
  encoding 'utf8'
  collation 'utf8_unicode_ci'
end

mysql_database_user 'gitlab' do
  connection mysql_connection_info
  password node['gitlab']['mysql_password']
  database_name 'gitlabhq_production'
  host 'localhost'
  privileges [:select, :update, :insert, :delete, :create, :drop, :index, :alter]
  action [:create, :grant]
end

# GitLab
execute "clone gitlab" do
  command "git clone https://github.com/gitlabhq/gitlabhq.git #{node['gitlab']['path']}"
  cwd node['gitlab']['home']
  user node['gitlab']['user']
  not_if { ::File.exists?(node['gitlab']['path']) }
end

%w{gitlab.yml unicorn.rb database.yml resque.yml}.each do |conf_file|
  template File.join(node['gitlab']['path'], 'config', conf_file) do
    user node['gitlab']['user']
    source "#{conf_file}.erb"
  end
end

%w{log tmp tmp/pids}.each do |dir|
  directory File.join(node['gitlab']['path'], dir) do
    user node['gitlab']['user']
    mode 0744
  end
end

directory node['gitlab']['satellites_path'] do
  user node['gitlab']['user']
end

gem_package 'charlock_holmes' do
  version '0.6.9'
end

execute 'bundle install' do
  command "bundle install --deployment --without development test postgres"
  user node['gitlab']['user']
  cwd node['gitlab']['path']
end

# TODO: Make idempotent or every chef run will reset the database!
execute "rake db:setup db:seed_fu" do
  command "bundle exec rake db:setup db:seed_fu RAILS_ENV=production"
  user node['gitlab']['user']
  cwd node['gitlab']['path']
  only_if { }
end

template "/etc/init.d/gitlab" do
  source "init_gitlab.erb"
  mode 0700
end

service "gitlab" do
  action [:enable, :start]
end

# Nginx

include_recipe "nginx"

execute "nxdissite default" do
  only_if { Dir['/etc/nginx/sites-enabled/*default'].count > 0 }
end

template "/etc/nginx/sites-available/gitlab" do
  source "nginx_gitlab.erb"
  mode 0644
end

execute "nxensite gitlab" do
  only_if { Dir['/etc/nginx/sites-enabled/gitlab'].count == 0 }
end

service "nginx" do
  action :restart
end