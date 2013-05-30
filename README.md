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

## With Vagrant (development mode)

By default vagrant will sync your LOCAL_GITLAB_DEV_PATH to /gitlabhq and run GitLab in development mode.
Set the environment variable to your local vagrant folder when running vagrant up.

`LOCAL_GITLAB_DEV_PATH=~/code/gitlabhq  vagrant up`, `vagrant ssh` and start foreman with `cd /gitlabhq && sudo foreman start`.

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

# Author

Author:: Andrew Fecheyr (<andrew@bedesign.be>)
