# References

* http://developer.github.com/v3/issues/
* github_api: https://github.com/peter-murach/github
 * http://rubydoc.info/github/peter-murach/github/master/frames

# Dependencies

```
sudo apt-get install libmysqlclient-dev
sudo apt-get install ruby1.9.1-dev
sudo apt-get install libxslt-dev libxml2-dev
sudo gem install github_api
sudo gem install mysql2
```
# Adapting to your own setup

* Fork to your own user / organization
* copy and modify configuration
 * cp config-sample.yml -> config.yml
 * cp env-sample.sh -> env.sh
* modify importer.rb
 * id_to_username: mapping between RedMine id and Github username
 * project_id_to_milestone: project id to milestone
 * you probably want to modify the mapping for other status below that
* Load environment variables
 * . env.sh
* Forward Mysql remote port to local (see forward.sh)
* Run importer.rb

# Limitations

* Does not handle code review assignment by linking to rv (must enter commit manually)
* Whoever runs the script is recorded as having opened the issue
* Attachments with uppercase letters in extension are not displayed in github

# Usage

Using environment variables: see env.sh

# LICENSE

MIT License