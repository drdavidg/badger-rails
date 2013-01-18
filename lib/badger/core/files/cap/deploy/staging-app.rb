load "deploy"
require 'rubygems'
require 'yaml'
require 'bundler/capistrano'
require './lib/badger_plugin.rb' if File.exists?("lib/badger_plugin.rb")

def test_file(full_path)
  'true' == capture("if [ -f #{full_path} ]; then echo 'true'; fi").strip
end

`git pull origin master`
YAML::ENGINE.yamler = 'syck'
yml = YAML.load_file "/opt/tmp/web/config/badger.yml"
name = yml[app_domain]['project_name']

yml.keys.each do |k|
  if k.include?("app")
    host_server = true
  end
end

begin
  database_yml = YAML.load_file "/opt/tmp/web/config/database_example.yml"
rescue
  host_server = false
  raise LoadError, "could not read from database_example.yml"
end

set :bundle_dir, ""
set :bundle_flags, ""
set :bundle_without, [:development, :test]
set :bundle_path, "/home/badger/.bundler"

set :application, "web"

set :repository,  "git@#{yml['domain']}:/opt/git/#{name}.git"
set :rails_env, "staging"

set :scm, :git
set :branch, "master"
set :git_enable_submodules, 1
set :git_shallow_clone, 1

default_run_options[:pty] = true #fix for teamcity
ssh_options[:auth_methods] = %w(publickey)
ssh_options[:keys] = %w(/root/.ssh/id_rsa)

set :user, "badger"
set :domain, yml[app_domain]['domain']

set :deploy_to, "/opt/#{application}"

set :use_sudo, true
set :keep_releases, 30

require 'san_juan'
role :app, domain
role :web, domain
role :db,  domain, :primary => true

san_juan.role :web, %w(nginx)
set :app_port, 4001

set :rake, "/opt/ruby/bin/rake"
set :default_environment, {
  'PATH' => '/opt/ruby/bin:/opt/rubygems/bin:$PATH',
  'GEM_HOME' => '/opt/rubygems'
}

namespace :configuration do
  task :db do
    run "cp #{release_path}/config/database_example.yml #{release_path}/config/database.yml"
  end
end

namespace :resque do
  task :prepare_resque, :roles => :app do
    if host_server
      resque_rake = "begin\n  require 'resque'\n  require 'resque/tasks'\n  task \"resque:setup\" => :environment\nrescue LoadError\nend"
      file = File.open("/opt/tmp/web/Rakefile")
      rakefile = file.read
      unless rakefile.include?(resque_rake)
        file = File.open("#{release_path}/Rakefile", "a+") {|f| f.write("\n\n" + resque_rake) }
      end
      run "/bin/bash -c 'source /etc/badger/core/teeth/resque.th; dbResque=#{database_yml['staging']['host']}; source /etc/badger/core/files/resque/resque.yml; resque_yml #{release_path}; config_resque #{release_path}'"
    end
  end

  task :load_config, :roles => :app do
    run "mkdir -p #{release_path}/config/god"
    run "rsync /etc/badger/core/files/god/angel/resque-dev.god #{release_path}/config/god/resque-dev.god"
    run "rsync /etc/badger/core/files/god/angel/resque-stg.god #{release_path}/config/god/resque-stg.god"
    run "rsync /etc/badger/core/files/god/angel/resque.god #{release_path}/config/god/resque.god"
    if File.exists?('/home/badger/resque-stg.god')
      run "sudo /opt/rubygems/bin/god load /home/badger/resque-stg.god"
    else
      run "sudo /opt/rubygems/bin/god load /etc/badger/core/files/god/angel/resque-stg.god"
    end
    if test_file("#{release_path}/config/god/resque_scheduler-stg.god")
      run "sudo /opt/rubygems/bin/god load #{release_path}/config/god/resque_scheduler-stg.god"
    end
    if test_file("#{release_path}/config/god/apn_sender-stg.god")
      run "sudo /opt/rubygems/bin/god load #{release_path}/config/god/apn_sender-stg.god"
    end
  end

  task :restart, :roles => :app do
    run "sudo /opt/rubygems/bin/god restart resque"
    if test_file("#{release_path}/config/god/resque_scheduler-stg.god")
      run "sudo /opt/rubygems/bin/god restart scheduler"
    end
    if test_file("#{release_path}/config/god/apn_sender-stg.god")
      run "sudo /opt/rubygems/bin/god restart apn_sender"
    end
  end
end

namespace :deploy do
  desc "Restarting services using"
  task :restart, :roles => :app, :except => { :no_release => true } do
    resque.prepare_resque
    resque.load_config
    resque.restart
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with passenger"
    task t, :roles => :app do ; end
  end

  task :badger_plugin do
    BadgerPlugin.new() if File.exists?("lib/badger_plugin.rb")
  end

  task :migrations do
    run "cd #{release_path} && #{rake} db:migrate RAILS_ENV=staging"
  end

  task :seeds do
    run "cd #{release_path} && #{rake} db:seed_fu RAILS_ENV=staging"
  end

  task :link_audio do
    run "ln -sf /opt/recordings #{release_path}/public/recordings"
  end
end

after 'deploy:finalize_update', :roles => :app do
  configuration.db
  deploy.migrations
  #deploy.seeds
  #deploy.link_audio
  deploy.cleanup
end
