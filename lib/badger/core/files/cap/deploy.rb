set :default_stage, "production"
set :stages, %w(staging production staging-app production-app)
require 'capistrano/ext/multistage'

set :rake, "env rake"

