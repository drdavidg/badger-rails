path = '/opt/ruby/bin:/opt/rubygems/bin:/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin'
rails_env = ENV['RAILS_ENV'] || "production"
rails_root = "/opt/web/current"
shared_dir = "/opt/web/shared"
num_of_workers = 3

num_of_workers.times do |num|
  God.watch do |w|
    w.name = "resque-#{num}"
    w.group = 'resque'
    w.interval = 30.seconds # default
    w.env = { 'PATH' => path, 'GEM_HOME' => '/opt/rubygems', 'RAILS_ENV' => rails_env, 'QUEUE' => 'default', 'VERBOSE' => 'true' }
    w.pid_file "#{shared_dir}/pids/unicorn.pid"
    w.start = "/opt/rubygems/bin/rake -f #{rails_root}/Rakefile -I #{rails_root} resque:work"
    w.log = "#{shared_dir}/log/god_resque_#{num}.log"

    w.start_grace   = 60.seconds
    w.restart_grace = 60.seconds

    w.uid = 'badger'
    w.gid = 'badger'

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 200.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 75.percent
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
end
