# SSL configuration
default['gitlab']['ssl'] = false
# Path on the VM to ssl certificate. You need to make sure the file get there
default['gitlab']['ssl_crt_path'] = ''
# Path on the VM to the unencrypted private key. You need to make sure the file get there
default['gitlab']['ssl_key_path'] = ''
