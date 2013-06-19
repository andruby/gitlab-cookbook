# Optional recipe to build a system wide ruby
# with https://github.com/fnichol/chef-rvm

# Otherwise libyaml-devel is unavailable
if platform?("redhat", "centos", "fedora", "amazon")
  include_recipe "yum::epel"
end

include_recipe "rvm::system"
rvm_gem "chef"
rvm_gem "bundler"

node.set['gitlab']['rvm_ruby'] = true
