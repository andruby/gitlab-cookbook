# gitlab cookbook

Chef cookbook to setup gitlab v5.2 according to [these instructions](https://github.com/gitlabhq/gitlabhq/blob/v5.2.0/doc/install/installation.md).

## Requirements

To contribute to and test this cookbook, we recommend installing [Vagrant](http://www.vagrantup.com/) and [vagrant-berkshelf](https://github.com/RiotGames/vagrant-berkshelf).

### Supported Platforms
* Ubuntu 12.04
* CentOS 6.4

## Attributes

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

## Usage

Installing Ruby and configuring Nginx are now  separated from the default recipe. This allows users to choose their prefered ruby installation and to use apache instead of nginx. (If you do use apache, please consider writing a recipe and opening a pull request).

There are three recipes in this cookbook to help you install ruby:

* `gitlab::ruby_package`: Install ruby through the OS package manager. Uses the `node['ruby_package']['version']` attribute. (Recommended for new user)
* `gitlab::ruby_build`: Compile ruby from source with [ruby_build](https://github.com/sstephenson/ruby-build). Uses the `node['ruby_build']['version']` attribute. (For advanced users)
* `gitlab::ruby_rvm`: Compile ruby via [rvm](https://rvm.io/). This recipe is a little less stable than the previous two recipes. Please open an issue or pull request if you encounter problems. Uses the `node['rvm']['default_ruby']` attribute.


### gitlab::default

Default recipe. Installs Gitlab and its dependencies. Configures it as a service that is started at boot time.

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

Make sure your node has ruby 1.9.3 installed. (eg: by using the `gitlab::ruby_package` recipe). You can optionally add the `gitlab::nginx`.

```json
{
  "run_list": [
  "recipe[gitlab::ruby_package]",
  "recipe[gitlab::default]",
  "recipe[gitlab::nginx]"
  ]
}
```

See the [Vagrantfile](https://github.com/andruby/gitlab-cookbook/blob/master/Vagrantfile) for a full example.

### gitlab::development

Recipe to set up most development requirements.

When I work on the GitlabHQ code I use this Vagrantfile (inside the GitlabHQ code directory):

```ruby
Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.
  config.berkshelf.enabled = true

  config.vm.hostname = "gitlab-dev"

  # Standard Ubuntu 12.04.2 base box
  config.vm.box = "ubuntu-12.04.2-amd64-chef-11-omnibus"
  config.vm.box_url = "http://grahamc.com/vagrant/ubuntu-12.04-omnibus-chef.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 3306, host: 3307  # MySQL
  config.vm.network :forwarded_port, guest: 3000, host: 3001  # Development Puma

  config.vm.provision :chef_solo do |chef|
    chef.log_level = :debug
    chef.json = {
      :mysql => {
        :server_root_password => 'rootpass',
        :server_debian_password => 'debpass',
        :server_repl_password => 'replpass',
        :bind_address => 'localhost'
      },
      :gitlab => {
        :mysql_password => 'gitlabpass'
      }
    }

    chef.add_recipe "gitlab::ruby_build"
    chef.add_recipe "gitlab::development"
  end
end
```

With this Berksfile:

```ruby
cookbook 'gitlab', :git => 'https://github.com/andruby/gitlab-cookbook.git'
```

When your VM is up and provisioned you should run `bundle install --without postgres` and `rake gitlab:setup` inside the VM in the `/vagrant` directory.

## Authors

* [Andrew Fecheyr](https://github.com/andruby) (<andrew@bedesign.be>)
* [Aimo Thiele](https://github.com/athiele) (<aimo.thiele@coremedia.com>)
* [tnarik](https://github.com/tnarik)
