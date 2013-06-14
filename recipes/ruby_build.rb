# Optional recipe to build a system wide ruby
# with https://github.com/fnichol/chef-ruby_build

# Compile ruby 1.9.3 from source
include_recipe "ruby_build"
ruby_build_ruby "1.9.3-p429" do
  prefix_path "/usr/local/"
  group "ruby"
end

# Install bundler with the correct ruby 1.9.3 gem binary
gem_package "bundler" do
  gem_binary "/usr/local/bin/gem"
end
