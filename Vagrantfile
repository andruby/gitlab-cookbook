# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set this to the path of your host machine's gitlab code
LOCAL_GITLAB_DEV_PATH = (ENV['LOCAL_GITLAB_DEV_PATH'] || "~/code/gitlabhq")


Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  config.berkshelf.enabled = true

  config.vm.hostname = "gitlab-berkshelf"

  # Standard Ubuntu 12.04.2 base box
  config.vm.box = "ubuntu-12.04.2-amd64"
  config.vm.box_url = "https://dl.dropbox.com/u/2894322/ubuntu-12.04.2-amd64.box"

  # CentOS 6.4 Box
  #config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130427.box"
  #config.vm.box = "nrel-centos6"


  config.vm.provider "virtualbox" do |v|
     v.customize ["modifyvm", :id, "--memory", 2048]
  end
 
  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :private_network, ip: "33.33.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.

  # config.vm.network :public_network

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 80, host: 8080    # Nginx
  config.vm.network :forwarded_port, guest: 3306, host: 3307  # MySQL
  config.vm.network :forwarded_port, guest: 3000, host: 3001  # Development Puma

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Syncing my own code version
  config.vm.synced_folder LOCAL_GITLAB_DEV_PATH, "/gitlabhq"

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      :mysql => {
        :server_root_password => 'rootpass',
        :server_debian_password => 'debpass',
        :server_repl_password => 'replpass',
        :bind_address => 'localhost'
      },
      :gitlab => {
        :mysql_password => 'k09vw7wa5s',
        :path => '/gitlabhq',
        :rails_env => 'development'
      }
    }

    chef.add_recipe "gitlab::default"
    # TODO: Extract fanout to separate cookbook
    chef.add_recipe "gitlab::fanout"

  end
end
