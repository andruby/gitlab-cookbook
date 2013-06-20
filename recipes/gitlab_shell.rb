# Clone Gitlab Shell
git "gitlab shell" do
  repository  node['gitlab']['shell_repository']
  revision    node['gitlab']['shell_revision']
  destination node['gitlab']['shell_path']
  user        node['gitlab']['user']
  group       node['gitlab']['group']
  action      :sync
end

template "gitlab-shell/config.yml" do
  path        File.join(node['gitlab']['shell_path'], 'config.yml')
  user        node['gitlab']['user']
  group       node['gitlab']['group']
  source      "gitlab_shell_config.yml.erb"
  notifies    :run, "execute[gitlab shell install]", :immediately
end

execute "gitlab shell install" do
  if node['gitlab']['rvm_ruby']
    command "source /etc/profile.d/rvm.sh && rvm use 1.9.3 && ./bin/install"
  else
    command  "./bin/install"
  end
  cwd         node['gitlab']['shell_path']
  user        node['gitlab']['user']
  action      :nothing
end