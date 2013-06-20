# Optional recipe to build a system wide ruby
# with https://github.com/fnichol/chef-ruby_build

# Prevent ruby_build recipe from compiling git from source
include_recipe "git"

include_recipe "ruby_build"

# Users part of the ruby group will be able to install gems
group "ruby"

group "ruby" do
  append true
  members node['gitlab']['user']
  action :nothing
  subscribes :modify, "user[#{node['gitlab']['user']}]", :immediate
end

# Compile ruby from source
ruby_build_ruby(node['ruby_build']['version']) do
  group "ruby"
  prefix_path "/usr/local/"
end

# Give users in the ruby group access to install/delete gems
bash "Set group write permission on ruby gem path" do
  code "chmod -R g+wt /usr/local/lib/ruby/gems"
end

# Install bundler with the correct ruby 1.9.3 gem binary
gem_package "bundler" do
  gem_binary "/usr/local/bin/gem"
end
