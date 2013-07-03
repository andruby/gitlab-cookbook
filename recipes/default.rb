#
# Cookbook Name:: gitlab
# Recipe:: default
#
# Configures a production ready stack for GitLab
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


# Load platform specific hacks and fixes
case node["platform"]
when "debian", "ubuntu"
  include_recipe "gitlab::debian"
when "redhat", "centos", "fedora"
  include_recipe "gitlab::redhat"
when "amazon"
  include_recipe "gitlab::redhat"
  include_recipe "gitlab::amazon_linux"
end

# Include cookbook dependencies
%w{ git build-essential readline xml zlib python::package python::pip
redisio::install redisio::enable mysql::server mysql::ruby }.each do |requirement|
  include_recipe requirement
end

# Gitlab user
user node['gitlab']['user'] do
  comment   "GitLab"
  home      node['gitlab']['home']
  shell     "/bin/bash"
  supports  :manage_home => true
end

# Don't allow login from user
user node['gitlab']['user'] do
  action :lock
end

# First install gitlab shell
include_recipe "gitlab::gitlab_shell"

# Clone the Gitlab repository
git "gitlab" do
  repository    node['gitlab']['repository']
  revision      node['gitlab']['revision']
  destination   node['gitlab']['path']
  user          node['gitlab']['user']
  group         node['gitlab']['group']
  action        :sync
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

# Install ruby gem dependencies
bash 'bundle install' do
  code "bundle install --deployment --without development test postgres"
  cwd node['gitlab']['path']
  user node['gitlab']['user']
end

# Database
mysql_connection_info = {
  :host => "localhost",
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

# Create the database user
mysql_database_user 'gitlab' do
  connection mysql_connection_info
  password node['gitlab']['mysql_password']
  database_name node['gitlab']['database_name']
  host 'localhost'
  action :create
end

# Create the database and notify grant and seed
mysql_database(node['gitlab']['database_name']) do
  connection mysql_connection_info
  encoding 'utf8'
  collation 'utf8_unicode_ci'
  action :create
  notifies :grant, "mysql_database_user[gitlab]", :immediately
  notifies :run, "bash[seed_database]", :immediately
end

# Seed the database
bash "seed_database" do
  code "bundle exec rake RAILS_ENV=#{node['gitlab']['rails_env']} db:setup"
  cwd node['gitlab']['path']
  user node['gitlab']['user']
  action :nothing
  notifies :run, "bash[create_admin]", :immediately
end

# Manually add the first administrator
# script contents from https://github.com/gitlabhq/gitlabhq/blob/master/db/fixtures/production/001_admin.rb
bash "create_admin" do
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
  code "bundle exec rails runner -e #{node['gitlab']['rails_env']} \"#{ruby_script}\""
  cwd node['gitlab']['path']
  user node['gitlab']['user']
  action :nothing
end

# Migrate the database
bash "migrations" do
  code "bundle exec rake RAILS_ENV=#{node['gitlab']['rails_env']} db:migrate"
  cwd node['gitlab']['path']
end

# Tell chef what the gitlab service supports
service "gitlab" do
  action [:enable, :start]
end

# Write the init file and enable the service
template "/etc/init.d/gitlab" do
  source "init_gitlab.erb"
  mode 0744
  notifies :restart, "service[gitlab]"
end

# I would love to use the directory resource for this. Unfortunately, this bug exists:
# http://tickets.opscode.com/browse/CHEF-1621
bash "Fix permisions" do
  code "chmod -R 755 #{node['gitlab']['home']}"
end
