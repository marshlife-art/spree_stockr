source 'https://rubygems.org'

#rvm stuff
#ruby=ruby-2.5.1
#ruby-gemset=marsh-spree

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree_core', github: 'spree/spree', branch: 'master'
gem 'spree_backend', github: 'spree/spree', branch: 'master'
# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: 'master'
gem 'rails-controller-testing'

gem 'roo', '~> 2.8'

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'rspec'
  gem 'rspec-rails'
end

gemspec
