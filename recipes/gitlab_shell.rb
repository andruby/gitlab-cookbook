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