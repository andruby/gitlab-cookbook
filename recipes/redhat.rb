# Redhat (and related) specific code

include_recipe "yum::epel"

%w{libicu-devel patch gcc-c++ readline-devel zlib-devel libffi-devel openssl-devel make autoconf automake libtool bison libxml2-devel libxslt-devel libyaml-devel}.each do |pkg|
  package pkg
end