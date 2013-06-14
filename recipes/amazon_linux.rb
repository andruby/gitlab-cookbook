# Amazon Linux specific code

# For ruby gem installation and rvm ruby build
bash "Install development tools to install ruby gems" do
  code "yum -y groupinstall 'Development Tools'"
end

# Remove default nginx site that conflicts
nginx_site '000-default' do
  enable false
end
