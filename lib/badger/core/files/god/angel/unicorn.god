# http://unicorn.bogomips.org/SIGNALS.html

RAILS_ENV = ENV['RAILS_ENV'] || 'production'
RAILS_ROOT = ENV['RAILS_ROOT'] || "/opt/web/current"
SHARED_DIR = "/opt/web/shared"

God.watch do |w|
  w.name = "unicorn"
  w.interval = 15.seconds # default
  w.env = { 'PATH' => '/opt/ruby/bin:/opt/rubygems/bin:/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin', 'GEM_HOME' => '/opt/rubygems' }

  # unicorn needs to be run from the rails root
  w.start = "cd #{RAILS_ROOT} && /opt/rubygems/bin/unicorn -c #{RAILS_ROOT}/config/unicorn.rb -E #{RAILS_ENV} -D"

  # QUIT gracefully shuts down workers
  w.stop = "kill -QUIT `cat #{SHARED_DIR}/pids/unicorn.pid`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{SHARED_DIR}/pids/unicorn.pid`"

  w.start_grace = 45.seconds
  w.restart_grace = 45.seconds
  w.pid_file = "#{SHARED_DIR}/pids/unicorn.pid"
  w.log = "#{SHARED_DIR}/log/god_unicorn.log"

  w.uid = 'badger'
  w.gid = 'badger'

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 500.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end
