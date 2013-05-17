# gitlab cookbook

Chef cookbook to setup gitlab v5.x according to [these instructions](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md).

# Requirements

To develop and test this cookbook, we recommend installing [Vagrant](http://www.vagrantup.com/) and [vagrant-berkshelf](https://github.com/RiotGames/vagrant-berkshelf).

# Usage

See the vagrantfile for minimum attributes needed.

`vagrant up` and visit `http://localhost:8080` after it finishes.

# Attributes

It is recommended that you change the following attributes:

* `node['gitlab']['root']['name']` – Name of the root user. (default: 'Administrator')
* `node['gitlab']['root']['email']` – Email of the root user. (default: 'admin@local.host')
* `node['gitlab']['root']['username']` – Username of the root user. (default: 'root')
* `node['gitlab']['root']['password']` – Password of the root user. (default: '5iveL!fe')

Set these attributes to match your server configuration:

* `node['gitlab']['url']` – Url to the gitlab instance. Used for api calls (default: 'http://localhost/')
* `node['gitlab']['host']` – Host name in gitlab.yml (default: 'localhost')
* `node['gitlab']['email_from']` – Email address used in the "From" field in mails sent by GitLab (default: 'gitlab@localhost')
* `node['gitlab']['support_email']` – Email address of your support contact (default: 'support@localhost')

See the `attributes/default.rb` file for the full list of attributes.

# Recipes

## Default

Default recipe. Installs Gitlab with all its dependencies. Configures it as a service that is started at boot time.

## Fanout

Optional recipe that installs [fanout](https://github.com/travisghansen/fanout) and enables it as an Upstart service.

# Author

Author:: Andrew Fecheyr (<andrew@bedesign.be>)
