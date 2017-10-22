source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'aws-sdk', '~> 3'
gem 'carrierwave-mongoid', require: 'carrierwave/mongoid'
gem 'fog-aws'
gem 'mongoid', '~> 6.1.0'
gem 'streamio-ffmpeg'
gem 'mail'
