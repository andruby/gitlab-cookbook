#
# Recipe for developing gitlabhq software
#
# Differences with default recipe:
#  * no git sync, rely on vagrant to sync the codebase
#  * regular bundle install --without postgres
#  * use the official gitlab db:setup for database setup

