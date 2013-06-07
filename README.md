# gitlab cookbook

Chef cookbook to setup gitlab v5.2 according to [these instructions](https://github.com/gitlabhq/gitlabhq/blob/v5.2.0/doc/install/installation.md).

# Requirements

To develop and test this cookbook, we recommend installing [Vagrant](http://www.vagrantup.com/) and [vagrant-berkshelf](https://github.com/RiotGames/vagrant-berkshelf).

#### Platforms
* Ubuntu 12.04
* CentOS 6.4

# Usage

## gitlab::default

Default recipe. Installs Gitlab with all its dependencies. Configures it as a service that is started at boot time.

Add `gitlab::default` to your node's run_list and make sure to set these attributes:

```json
{
  "mysql": {
    "server_repl_password": "XXX",
    "server_debian_password": "XXX",
    "server_root_password": "XXX"
  },
  "gitlab": {
    "root": {
      "name": "Administrator",
      "email": "admin@example.com",
      "username": "root",
      "password": "5iveL!fe"
    },
    "url": "http://example.com",
    "host": "example.com",
    "email_from": "gitlab@example.com",
    "support_email": "support@example.com"
  }
}
```

When running on CentOS, you also have to provide the following RVM configuration:

```json
"rvm" : {
  "default_ruby" : "1.9.3",
  "global_gems" : [
    {"name" : "bundler"},
    {"name" : "chef"}
  ]
}
```

## gitlab::fanout

Optional recipe that installs [fanout](https://github.com/travisghansen/fanout) and enables it as an Upstart service.

## With Vagrant from an other repository

When I work on the GitlabHQ code I use this Vagrantfile (inside the GitlabHQ code directory):

```ruby
Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  config.berkshelf.enabled = true

  config.vm.hostname = "gitlab-dev"

  # Standard Ubuntu 12.04.2 base box
  config.vm.box = "ubuntu-12.04.2-amd64"
  config.vm.box_url = "https://dl.dropbox.com/u/2894322/ubuntu-12.04.2-amd64.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 3306, host: 3307  # MySQL
  config.vm.network :forwarded_port, guest: 3000, host: 3001  # Development Puma

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
        :path => '/vagrant',
        :rails_env => 'development',
        :sync_repository => false,
        :bundle_install_cmd => 'bundle install --without postgres'
      }
    }

    chef.add_recipe "gitlab::default"
  end
end
```

Note the `path`, `sync_repository`, `rails_env` and `bundle_install_cmd` used to set gitlab in development mode.

With this Berksfile

```
cookbook 'gitlab', :git => 'https://github.com/andruby/gitlab-cookbook.git'
```

# Attributes

It is recommended that you change the following attributes:

* `node['gitlab']['root']['name']` - Name of the root user. (default: 'Administrator')
* `node['gitlab']['root']['email']` - Email of the root user. (default: 'admin@local.host')
* `node['gitlab']['root']['username']` - Username of the root user. (default: 'root')
* `node['gitlab']['root']['password']` - Password of the root user. (default: '5iveL!fe')

Set these attributes to match your server configuration:

* `node['gitlab']['url']` - Url to the gitlab instance. Used for api calls (default: 'http://localhost/')
* `node['gitlab']['host']` - Host name in gitlab.yml (default: 'localhost')
* `node['gitlab']['email_from']` - Email address used in the "From" field in mails sent by GitLab (default: 'gitlab@localhost')
* `node['gitlab']['support_email']` - Email address of your support contact (default: 'support@localhost')

See the `attributes/default.rb` file for the full list of attributes.

# Authors

* [Andrew Fecheyr](https://github.com/andruby) (<andrew@bedesign.be>)
* [Aimo Thiele](https://github.com/athiele) (<aimo.thiele@coremedia.com>)
* [tnarik](https://github.com/tnarik)
