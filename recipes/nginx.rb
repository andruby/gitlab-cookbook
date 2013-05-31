# Nginx

include_recipe "nginx"

nginx_site 'default' do
  enable false
end

