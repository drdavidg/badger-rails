rails_env = ENV['RAILS_ENV'] || 'staging'

# 16 workers and 1 master
worker_processes 2

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
preload_app true

# Restart any workers that haven't responded in 30 seconds
timeout 90

# Listen on a Unix data socket
listen '/tmp/unicorn.sock'

working_directory "/opt/web/current"
pid "/opt/web/shared/pids/unicorn.pid"

stderr_path "/opt/web/shared/log/unicorn.stderr.log"
stdout_path "/opt/web/shared/log/unicorn.stdout.log"

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!

  old_pid = '/opt/web/shared/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  begin
      uid, gid = Process.euid, Process.egid
      user, group = 'badger', 'badger'
      target_uid = Etc.getpwnam(user).uid
      target_gid = Etc.getgrnam(group).gid
      worker.tmp.chown(target_uid, target_gid)
      if uid != target_uid || gid != target_gid
        Process.initgroups(user, target_gid)
        Process::GID.change_privilege(target_gid)
        Process::UID.change_privilege(target_uid)
      end
    rescue => e
      if rails_env == 'staging'
        STDERR.puts "couldn't change user, oh well"
      else
        raise e
      end
    end

end
