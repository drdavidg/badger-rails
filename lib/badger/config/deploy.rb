#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'

def remote_file_exists?(full_path)
  'true' ==  capture("if [ -d #{full_path} ]; then echo 'true'; fi").strip
end

def remote_directory_empty?(full_path)
  'true' ==  capture('[ "$(ls -A /opt/git/)" ] && echo "false" || echo "true"').strip
end

def check_local_db(teh_yml)
  if teh_yml['local_db'] == nil or teh_yml['local_db'] == true
    puts
    puts "Worker servers cannot be deployed with a local project database."
    puts "Please use an exteral database."
    puts
    exit
  end
end

yml = YAML.load_file "config/rails-app.yml"
set :user, yml['username']
set :password, yml['password']
set :domain, yml['domain']
set :port, yml['port']
set :server, yml['server']
set :environment, yml['environment']

role :web, domain

desc "host"
task ARGV[0], :roles => :web do
  case ARGV[1]
  when "db_setup", "db_sync", "db_deploy"
    roles[:app].clear
    roles[:web].clear
    set :user, yml['db']['username']
    set :password, yml['db']['password']
    set :domain, yml['db']['domain']
    set :port, yml['db']['port']
    role :db, domain
  when "app_setup", "app_sync", "app_deploy", "scale"
    roles[:app].clear
    roles[:web].clear
    set :user, yml[ARGV[0]]['username']
    set :password, yml[ARGV[0]]['password']
    set :domain, yml[ARGV[0]]['domain']
    set :port, yml[ARGV[0]]['port']
    role :app, domain
  end
end

desc "info"
task :info, roles => :web do
  run "cd /etc/badger/core/scripts/; chmod +x app_info; ./app_info"
end

desc "scale"
task :scale, roles => :app do
  run "cd /etc/badger/core/scripts/; chmod +x app_scale; ./app_scale #{workers} #{yml['environment']}"
end

desc "exists"
task :exists, roles => :web do
  if remote_file_exists?("/opt/git/#{ARGV[0]}.git")
    puts "true"
  end
end

desc "createExists"
task :createExists, roles => :web do
  if remote_directory_empty?("/opt/git/#{ARGV[0]}.git")
    puts "false"
  else
    puts "true"
  end
end

desc "sync"
task :sync, :roles => :web do
  upload "../badger/core", "/etc/badger/", :via => :scp, :recursive => :true
end

desc "db_sync"
task :db_sync, :roles => :db do
  upload "../badger/core", "/etc/badger/", :via => :scp, :recursive => :true
end

desc "app_sync"
task :app_sync, :roles => :app do
  upload "../badger/core", "/etc/badger/", :via => :scp, :recursive => :true
end

desc "setup"
task :setup, :roles => :web do
  `cat ~/.ssh/id_rsa.pub >> core/files/ssh/authorized_keys`
  run <<EOF
mkdir -p /etc/badger/core;
[ "$(cat /etc/issue | grep CentOS)" ] && rpm -Uvh https://github.com/downloads/curiousminds/packages/epel-release-6-5.noarch.rpm;
[ "$(cat /etc/issue | grep CentOS)" ] && yum -y repolist;
[ "$(cat /etc/issue | grep CentOS)" ] && yum -y install git && yum -y update git;
[ "$(cat /etc/issue | grep Red)" ] && rpm -Uvh https://github.com/downloads/curiousminds/packages/epel-release-6-5.noarch.rpm;
[ "$(cat /etc/issue | grep Red)" ] && yum -y repolist;
[ "$(cat /etc/issue | grep Red)" ] && yum -y install git && yum -y update git;
[ "$(cat /etc/issue | grep Red)" ] && yum -y update git;
[ "$(cat /etc/issue | grep Ubuntu)" ] && apt-get update;
[ "$(cat /etc/issue | grep Ubuntu)" ] && apt-get -y install git-core;
[ "$(cat /etc/issue | grep Debian)" ] && apt-get update;
[ "$(cat /etc/issue | grep Debian)" ] && apt-get -y install git-core;
EOF
end

desc "db_setup"
task :db_setup, :roles => :db do
  `cat ~/.ssh/id_rsa.pub >> core/files/ssh/authorized_keys`
  run <<EOF
mkdir -p /etc/badger/core;
[ "$(cat /etc/issue | grep CentOS)" ] && rpm -Uvh https://github.com/downloads/curiousminds/packages/epel-release-6-5.noarch.rpm;
[ "$(cat /etc/issue | grep CentOS)" ] && yum -y repolist;
[ "$(cat /etc/issue | grep CentOS)" ] && yum -y install git && yum -y update git;
[ "$(cat /etc/issue | grep Red)" ] && rpm -Uvh https://github.com/downloads/curiousminds/packages/epel-release-6-5.noarch.rpm;
[ "$(cat /etc/issue | grep Red)" ] && yum -y repolist;
[ "$(cat /etc/issue | grep Red)" ] && yum -y install git && yum -y update git;
[ "$(cat /etc/issue | grep Red)" ] && yum -y update git;
[ "$(cat /etc/issue | grep Ubuntu)" ] && apt-get update;
[ "$(cat /etc/issue | grep Ubuntu)" ] && apt-get -y install git-core;
[ "$(cat /etc/issue | grep Debian)" ] && apt-get update;
[ "$(cat /etc/issue | grep Debian)" ] && apt-get -y install git-core;
EOF
end

desc "app_setup"
task :app_setup, :roles => :app do
  `cat ~/.ssh/id_rsa.pub >> core/files/ssh/authorized_keys`
  run <<EOF
mkdir -p /etc/badger/core;
[ "$(cat /etc/issue | grep CentOS)" ] && rpm -Uvh https://github.com/downloads/curiousminds/packages/epel-release-6-5.noarch.rpm;
[ "$(cat /etc/issue | grep CentOS)" ] && yum -y repolist;
[ "$(cat /etc/issue | grep CentOS)" ] && yum -y install git && yum -y update git;
[ "$(cat /etc/issue | grep Red)" ] && rpm -Uvh https://github.com/downloads/curiousminds/packages/epel-release-6-5.noarch.rpm;
[ "$(cat /etc/issue | grep Red)" ] && yum -y repolist;
[ "$(cat /etc/issue | grep Red)" ] && yum -y install git && yum -y update git;
[ "$(cat /etc/issue | grep Red)" ] && yum -y update git;
[ "$(cat /etc/issue | grep Ubuntu)" ] && apt-get update;
[ "$(cat /etc/issue | grep Ubuntu)" ] && apt-get -y install git-core;
[ "$(cat /etc/issue | grep Debian)" ] && apt-get update;
[ "$(cat /etc/issue | grep Debian)" ] && apt-get -y install git-core;
EOF
end

desc "db_deploy"
task :db_deploy, :roles => :db do
  run "chmod +x /etc/badger/core/claws/#{ARGV[0]}.claw; /etc/badger/core/claws/./#{ARGV[0]}.claw"
end

desc "app_deploy"
task :app_deploy, :roles => :app do
  check_local_db(yml)
  run "chmod +x /etc/badger/core/claws/app.claw; /etc/badger/core/claws/./app.claw"
end

desc "deploy"
task :deploy, :roles => :web do
  if Dir.exists?("../badger/core/scripts/badger/")
    upload "../badger/core/scripts/badger", "/etc/badger/core/scripts/", :via => :scp, :recursive => :true
  end
  run "chmod +x /etc/badger/core/claws/#{ARGV[0]}.claw; /etc/badger/core/claws/./#{ARGV[0]}.claw"
end

desc "gemset_clear"
task :gemset_clear, :roles => :web do
  run "cd /etc/badger/core/scripts/; chmod +x *; ./remove_gems"
end

desc "git"
task :git, :roles => :web do
  ssh = `cat ~/.ssh/id_rsa.pub`
  run "groupadd git; useradd -m git -g git && mkdir -p /home/git/.ssh/ && touch /home/git/.ssh/authorized_keys; chown git /home/git/.ssh; echo #{ssh} >> /home/git/.ssh/authorized_keys"
  run "mkdir -p /opt/git/#{ARGV[0]}.git; cd /opt/git/#{ARGV[0]}.git; git --bare init; chown -R git:git /opt/git/;"
  run "echo git@#{yml['domain']}:/opt/git/#{ARGV[0]}.git > /etc/badger/core/files/git/git"
end

desc "rake"
task :rake, :roles => :web do
  run "cd /opt/web/current/; PATH=/opt/rubygems/bin:$PATH; rake #{brat.gsub("^", " ")} RAILS_ENV=#{environment}"
end

desc "logs"
task :logs, :roles => :web do
  if brat == "tail"
    trap("INT") do
      run "pkill tail"
      exit
    end
    run "tail -f /opt/web/current/log/#{yml['environment']}.log /opt/web/current/log/god_unicorn.log /var/log/nginx/access.log /var/log/nginx/error.log"
  else
    run "tail /opt/web/current/log/#{yml['environment']}.log /opt/web/current/log/god_unicorn.log /var/log/nginx/access.log /var/log/nginx/error.log"
  end
end

desc "remove"
task :remove, :roles => :web do
  run "cd /etc/badger/core/scripts/; chmod +x remove_app; ./remove_app #{ARGV[0]}"
end

desc "removedb"
task :removedb, :roles => :web do
  run "cd /etc/badger/core/scripts/; chmod +x remove_app_db; ./remove_app_db #{ARGV[0]}"
end
