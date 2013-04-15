# Nginx

include_recipe "nginx"

execute "nxdissite default" do
  only_if { Dir['/etc/nginx/sites-enabled/*default'].count > 0 }
  notifies :restart, "service[nginx]"
end

service "nginx" do
  supports :restart => true, :start => true, :stop => true, :status => true
  action :nothing
end