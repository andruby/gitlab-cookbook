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

# This Recipe tries to follow the installation instructions at https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md (v5.2 at time of writing).

# Check if mysql password is set
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

case node["platform"]
when "debian", "ubuntu"
  include_recipe "apt::default"
when "redhat", "centos", "fedora", "amazon"
  include_recipe "yum::epel"
end

# Include cookbook dependencies

if platform?("amazon")
  # For ruby gem installation and rvm ruby build
  bash "Install development tools to install ruby gems" do
    code <<-EOH
    yum -y groupinstall 'Development Tools'
    EOH
  end
end

%w{ git build-essential readline xml zlib python::package python::pip
redisio::install redisio::enable mysql::server mysql::ruby nginx }.each do |requirement|
  include_recipe requirement
end

case node["platform"]
when "debian", "ubuntu"
  %w{ ruby1.9.1 ruby1.9.1-dev curl libicu-dev }.each do |pkg|
    package pkg
  end
when "redhat", "centos", "fedora", "amazon"
  %w{libicu-devel patch gcc-c++ readline-devel zlib-devel libffi-devel openssl-devel make autoconf automake libtool bison libxml2-devel libxslt-devel libyaml-devel}.each do |pkg|
    package pkg
  end

  include_recipe "rvm::system"
end

# Git user
user node['gitlab']['user'] do
  comment   "GitLab"
  home      node['gitlab']['home']
  shell     "/bin/bash"
  supports  :manage_home => true
end

user node['gitlab']['user'] do
  action :lock
end

include_recipe "gitlab::nginx"
include_recipe "gitlab::gitlab_shell"

# Database
mysql_connection_info = {:host => "localhost",
                         :username => 'root',
                         :password => node['mysql']['server_root_password']}

mysql_database_user 'gitlab' do
  connection mysql_connection_info
  password node['gitlab']['mysql_password']
  database_name node['gitlab']['database_name']
  host 'localhost'
  privileges [:select, :update, :insert, :delete, :create, :drop, :index, :alter]
  action :create
end

# Clone the Gitlab repository
git "gitlab" do
  repository    node['gitlab']['repository']
  revision      node['gitlab']['revision']
  destination   node['gitlab']['path']
  user          node['gitlab']['user']
  group         node['gitlab']['group']
  action        :sync
  only_if       { node['gitlab']['sync_repository'] }
end

# Write config files for gitlab, puma and resque
%w{gitlab.yml puma.rb database.yml resque.yml}.each do |conf_file|
  template File.join(node['gitlab']['path'], 'config', conf_file) do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    source "#{conf_file}.erb"
  end
end

# Make sure GitLab can write to the log/, tmp/ and public/uploads directories
%w{log tmp tmp/pids tmp/sockets public/uploads}.each do |dir|
  directory File.join(node['gitlab']['path'], dir) do
    owner node['gitlab']['user']
    group node['gitlab']['group']
    mode 0744
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

if platform?("ubuntu")
  # Install gems
  gem_package "bundler"
  gem_package 'charlock_holmes' do
    version '0.6.9.4'
  end
else

  bash "Install charlock_holmes gem" do
    code <<-EOH
    source /etc/profile.d/rvm.sh
    rvm use #{node['rvm']['default_ruby']}
    gem install charlock_holmes --version '0.6.9.4'
    EOH
  end
end

execute 'bundle install' do
  command node['gitlab']['bundle_install_cmd']
  cwd node['gitlab']['path']
  user node['gitlab']['user']
end

# Create the database and notify grant and seed
mysql_database(node['gitlab']['database_name']) do
  connection mysql_connection_info
  encoding 'utf8'
  collation 'utf8_unicode_ci'
  action :create
  notifies :grant, "mysql_database_user[gitlab]", :immediately
  notifies :run, "execute[seed_database]", :immediately
end

# Seed the database
execute "seed_database" do
  command "bundle exec rake RAILS_ENV=#{node['gitlab']['rails_env']} db:setup"
  cwd node['gitlab']['path']
  user node['gitlab']['user']
  action :nothing
  notifies :run, "execute[create_admin]", :immediately
end

# Manually add the first administrator
# script contents from https://github.com/gitlabhq/gitlabhq/blob/master/db/fixtures/production/001_admin.rb
execute "create_admin" do
  ruby_script = <<-EOS
  admin = User.create!(
    email: '#{node['gitlab']['root']['email']}',
    name: '#{node['gitlab']['root']['name']}',
    username: '#{node['gitlab']['root']['username']}',
    password: '#{node['gitlab']['root']['password']}',
    password_confirmation: '#{node['gitlab']['root']['password']}')
  admin.projects_limit = 10000
  admin.admin = true
  admin.save!
  EOS
  command "bundle exec rails runner -e #{node['gitlab']['rails_env']} \"#{ruby_script}\""
  cwd node['gitlab']['path']
  user node['gitlab']['user']
  action :nothing
end

# Migrate the database
execute "migrations" do
  command "bundle exec rake RAILS_ENV=#{node['gitlab']['rails_env']} db:migrate"
  cwd node['gitlab']['path']
end

service "gitlab" do
  supports :restart => true, :start => true, :stop => true, :status => true
  action :nothing
end

template "/etc/init.d/gitlab" do
  source "init_gitlab.erb"
  mode 0744
  notifies :enable, "service[gitlab]"
  notifies :start, "service[gitlab]"
end

template "/etc/nginx/sites-available/gitlab" do
  source "nginx_gitlab.erb"
  mode 0644
  notifies :reload, "service[nginx]"
end

nginx_site "gitlab"

# I would love to use the directory resource for this. Unfortunately, this bug exists:
# http://tickets.opscode.com/browse/CHEF-1621
bash "Fix permisions" do
  code "chmod -R 755 #{node['gitlab']['home']}"
end
