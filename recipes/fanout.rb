# Optional recipe that install an Upstart init script for
# https://github.com/travisghansen/fanout

# directory "#{Chef::Config[:file_cache_path]}/fanout/" do
#   not_if { File.exists?(node['fanout']['path']) }
# end


directory(node['fanout']['dir'])

remote_file "#{node['fanout']['dir']}/fanout.c" do
  source "https://github.com/travisghansen/fanout/raw/master/fanout.c"
  notifies :run, "execute[make_fanout]"
end

remote_file "#{node['fanout']['dir']}/Makefile" do
  source "https://github.com/travisghansen/fanout/raw/master/Makefile"
  notifies :run, "execute[make_fanout]"
end

execute "make_fanout" do
  command "make"
  cwd node['fanout']['dir']
  action :nothing
  notifies :restart, "service[fanout]"
end

link(node['fanout']['bin']) do
  to "#{node['fanout']['dir']}/fanout"
end

template "/etc/init/fanout.conf" do
  source "fanout.conf.erb"
  mode 0644
  options = %w{port run-as client-limit logfile max-logfile-size}.map do |opt|
    "--#{opt}=#{node['fanout'][opt]}" if node['fanout'][opt]
  end
  variables(:options => options.compact.join(' '))
  notifies :start, "service[fanout]"
end

service "fanout" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true, :start => true, :stop => true, :status => true
  action :enable
end
