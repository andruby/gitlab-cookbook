# Optional recipe to build a system wide ruby
# with https://github.com/fnichol/chef-rvm

include_recipe "rvm::default"

rvm_default_ruby "1.9.3" do
  action :create
end

rvm_gem "bundler"

