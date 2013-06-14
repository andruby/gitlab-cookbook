# Install & configure nginx as a reverse proxy for GitLab

include_recipe "nginx"

# Disable default nginx site
nginx_site 'default' do
  enable false
end

# Write the nginx config file for gitlab
template "/etc/nginx/sites-available/gitlab" do
  source "nginx_gitlab.erb"
  mode 0644
  notifies :reload, "service[nginx]"
end

# Enable gitlab site
nginx_site "gitlab"