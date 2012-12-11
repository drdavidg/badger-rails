load "deploy"
load "deploy/assets"
require 'rubygems'
require 'yaml'
require 'bundler/capistrano'
require './lib/badger_plugin.rb' if File.exists?("lib/badger_plugin.rb")

`git pull origin master`
YAML::ENGINE.yamler = 'syck'
yml = YAML.load_file "/opt/tmp/web/config/badger.yml"
name = `cat /etc/badger/core/files/badger/info`

yml.keys.each do |k|
  if k.include?("app")
    host_server = true
  end
end
begin
  database_yml = YAML.load_file "/opt/tmp/web/config/database_example.yml"
rescue
  host_server = false
end

set :bundle_dir, ""
set :bundle_flags, ""
set :bundle_without, [:development, :test]
set :bundle_path, "/home/badger/.bundler"

set :application, "web"

set :repository,  "git@#{yml['domain']}:/opt/git/#{name.chomp}.git"
set :rails_env, "staging"

set :scm, :git
set :branch, "master"
set :git_enable_submodules, 1
set :git_shallow_clone, 1

default_run_options[:pty] = true #fix for teamcity
ssh_options[:auth_methods] = %w(publickey)
ssh_options[:keys] = %w(/root/.ssh/id_rsa)

set :user, "badger"
set :domain, "#{yml['domain']}"

set :deploy_to, "/opt/#{application}"

set :use_sudo, true
set :keep_releases, 30

require 'san_juan'
role :app, domain
role :web, domain
role :db,  domain, :primary => true

san_juan.role :web, %w(nginx)
set :app_port, 4001

set :rake, "bundle exec /opt/rubygems/bin/rake"
set :default_environment, {
  'PATH' => '/usr/bin:/bin/bash:/opt/ruby/bin:/opt/rubygems/bin:$PATH',
  'GEM_HOME' => '/opt/rubygems'
}

namespace :configuration do
  task :resque, :roles => :app do
    if host_server == true
      run "/bin/bash -c 'source /etc/badger/core/teeth/resque.th; dbResque=#{database_yml['staging']['host']}; source /etc/badger/core/files/resque/resque.yml; resque_yml #{release_path}; config_resque #{release_path}'"
    end
  end

  task :db do
    if yml['local_db'] == false
      run "cp -rf #{release_path}/config/database_example.yml #{release_path}/config/database.yml"
    else
      run "cp -rf /etc/badger/core/files/mysql/database.yml #{release_path}/config/database.yml"
    end
    run "cp -rf /etc/badger/core/files/god/unicorn-stg.rb #{release_path}/config/unicorn-stg.rb"
    run "cp -rf /etc/badger/core/files/god/unicorn.rb #{release_path}/config/unicorn.rb"
  end
end

namespace :unicorn do
  task :load_config, :roles => :app do
    run "mkdir -p #{release_path}/config/god"
    run "rsync /etc/badger/core/files/god/angel/resque-dev.god #{release_path}/config/god/resque-dev.god"
    run "rsync /etc/badger/core/files/god/angel/resque-stg.god #{release_path}/config/god/resque-stg.god"
    run "rsync /etc/badger/core/files/god/angel/resque.god #{release_path}/config/god/resque.god"
    run "sudo /opt/rubygems/bin/god load /etc/badger/core/files/god/angel/unicorn-stg.god"
  end

  task :restart, :roles => :app do
    run "sudo /opt/rubygems/bin/god restart unicorn"
  end
end

namespace :deploy do
  desc "Restarting unicorn using"
  task :restart, :roles => :app, :except => { :no_release => true } do
    unicorn.load_config
    unicorn.restart
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with passenger"
    task t, :roles => :app do ; end
  end

  task :badger_plugin do
    BadgerPlugin.new() if File.exists?("lib/badger_plugin.rb")
  end

  task :migrations do
    run "cd #{release_path} && #{rake} db:migrate RAILS_ENV=staging --trace"
  end

  task :seeds do
    run "cd #{release_path} && #{rake} db:seed_fu RAILS_ENV=staging"
  end

  task :link_audio do
    run "ln -sf /opt/recordings #{release_path}/public/recordings"
  end
end

after 'deploy:finalize_update', :roles => :app do
  configuration.resque
  configuration.db
  deploy.badger_plugin
  deploy.migrations
  #deploy.seeds
  #deploy.link_audio
  deploy.cleanup
end
