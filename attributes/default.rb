# User account that will run gitlab
default['gitlab']['user'] = "git"
default['gitlab']['group'] = "git"
default['gitlab']['home'] = "/home/git/"

# Path where gitlab codebase will be installed
default['gitlab']['path'] = "/home/git/gitlab"
# Path where gitlab-shell will be installed
default['gitlab']['shell_path'] = "/home/git/gitlab-shell"
# Path where the git repos will be stored
default['gitlab']['repos_path'] = "/home/git/repositories"
# Path where the git satellites will be stored
default['gitlab']['satellites_path'] = "/home/git/gitlab-satellites"

# gitlab git clone repository & version
default['gitlab']['repository'] = "https://github.com/gitlabhq/gitlabhq.git"
default['gitlab']['revision'] = 'v5.2.0'
# gitlab-shell git clone repository & version
default['gitlab']['shell_repository'] = "https://github.com/gitlabhq/gitlab-shell.git"
default['gitlab']['shell_revision'] = 'v1.4.0'

default['gitlab']['http_port'] = '80'
default['gitlab']['https_port'] = '443'

default['gitlab']['rails_env'] = 'production'
default['gitlab']['database_name'] = 'gitlabhq'

# Url to gitlab instance. Used for api calls
default['gitlab']['url'] = "http://localhost/"

## Gitlab.yml config
if platform?("amazon")
default['gitlab']['host'] = '$HOSTNAME'
else
default['gitlab']['host'] = 'localhost'
end
default['gitlab']['email_from'] = 'gitlab@localhost'
default['gitlab']['support_email'] = 'support@localhost'
default['gitlab']['socket'] = '/tmp/gitlab.socket'
