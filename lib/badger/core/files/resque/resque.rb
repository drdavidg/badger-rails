require 'resque'
require 'resque/server'
require 'yaml'

Resque.redis = YAML.load_file("#{Rails.root}/config/resque.yml")["#{Rails.env}"]["server"]
