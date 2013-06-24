# Optional recipe to install a system wide ruby
# from the OS package manager

package(node['ruby_package']['version'])

gem_package "bundler"
