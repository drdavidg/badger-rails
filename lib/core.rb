module Methods
  attr_accessor :yml

  def initialize
    @errors = Errors.new
    spec = Gem::Specification.find_by_name("badger-rails")
    @badger_root = spec.gem_dir + "/lib/"
  end

  def badger_logs
    gem_setup
    Dir.chdir(@badger_root + "badger/")
    if ARGV[1] == "tail"
      trap("INT") do
        puts
        puts "Killing tail signal.."
        puts
      end
      `cap rails-app logs -s brat=tail`
    else
      `cap rails-app logs -s brat=nil`
    end
  end

  def database_server(app_claw)
    command = "#{app_claw}db-app.claw > #{app_claw}app.tmp; mv #{app_claw}app.tmp #{app_claw}db-app.claw"
    case @yml['db']['redis']
    when true
      `sed 's/.*install_source_redis.*/install_source_redis/g' #{command}`
    when false
      `sed 's/.*install_source_redis.*/#install_source_redis/g' #{command}`
    else
      `sed 's/.*install_source_redis.*/#install_source_redis/g' #{command}`
    end
    `cap db-app db_setup;
    cap db-app db_sync;
    cap db-app db_deploy`
    puts <<EOF

Database server deployed.

If you do not have a web project built.
Run: badger create < name >

Or if a project already exists.
Run: git commit -m "database config"
Run: git push badger master
Run: badger deploy

EOF
  end

  def db
    gem_setup('db')
    Dir.chdir(@badger_root + "badger/")
    app_claw = @badger_root + "badger/core/claws/"
    ensure_ssh
    database_server(app_claw)
    #TODO write to info file.
  end

  def create(app = nil)
    gem_setup
    Dir.chdir(@badger_root + "badger/")
    app_claw = @badger_root + "badger/core/claws/"
    ensure_ssh
    if app.nil?
      rails_server(app_claw)
    else
      worker_server(app_claw, app)
    end
  end

  def ensure_badger_yml
    if not File.exists?("badger.yml")
      @errors.errors('yaml exists')
      exit
    end
  end

  def ensure_external_db
    @yml = YAML.load_file(@rails_root + "/config/badger.yml")
    if @yml['local_db'].nil? or @yml['local_db'] == true
      @errors.errors('local db')
      exit
    end
  end

  def ensure_rails_root
    config_dir = Dir.exists?("config/")
    if config_dir
      @rails_root = Dir.pwd
      Dir.chdir("config/")
    else
      while not Dir.pwd == "/"
        if Dir.exists?("config/")
          break
        else
          Dir.chdir("..")
        end
      end
      if Dir.pwd == "/"
        @errors.errors('rails root')
        exit
      else
        @rails_root = Dir.pwd
        Dir.chdir("config/")
      end
    end
  end

  def ensure_ssh
    if not File.exists?("#{Dir.home}/.ssh/id_rsa.pub")
        @errors.errors('ssh')
      exit
    end
  end

  def exists_error
    @errors.errors('rails project')
    exit
  end

  def gem_setup(db = nil)
    ensure_badger_yml
    @yml = YAML.load_file(@rails_root + "/config/badger.yml")
    `echo git@#{@yml['domain']}:/opt/git/#{ARGV[1]}.git > #{@badger_root}badger/core/files/git/git`
    `echo #{ARGV[1]} > #{@badger_root}badger/core/files/badger/info`
      FileUtils.cp(Dir.pwd + "/badger.yml", @badger_root + "badger/config/rails-app.yml")
    unless db.nil?
      db_yml = YAML.load_file(Dir.pwd + "/database_example.yml")
      if @yml['db']['connection_internal'] == true
        connection = '10%'
      else
        connection = '%'
      end

      db_settings = <<-eos
#{db_yml['staging']['username']}
#{db_yml['staging']['password']}
#{db_yml['staging']['database']}
#{db_yml['production']['username']}
#{db_yml['production']['password']}
#{db_yml['production']['database']}
#{connection}
      eos

      File.open(@badger_root + "badger/core/files/mysql/db_stats", 'w') {|f| f.write(db_settings)}
    end
  end

  def git_msg
    puts <<EOF

Badger is now setup.
A remote has been added for git@#{@yml['domain']}:/opt/git/#{ARGV[1]}.git

Usage:
git add .
git commit -m "first badger commit"
git push badger master
badger deploy

EOF
  end

  def info
    gem_setup
    Dir.chdir(@badger_root + "badger/")
    app_claw = @badger_root + "badger/core/claws/"
    ensure_ssh
    exists = `cap #{ARGV[1]} createExists`
    info_error if exists.chomp == "false"
    `cap rails-app info`
  end

  def info_error
    @errors.errors('info error')
    exit
  end

  def rails_server(app_claw)
    command = "#{app_claw}rails-app.claw > #{app_claw}app.tmp; mv #{app_claw}app.tmp #{app_claw}rails-app.claw"
    case @yml['redis']
    when true
      `sed 's/.*install_source_redis.*/install_source_redis/g' #{command}`
    when false
      `sed 's/.*install_source_redis.*/#install_source_redis/g' #{command}`
    else
      `sed 's/.*install_source_redis.*/#install_source_redis/g' #{command}`
    end

    if @yml['environment'] == "production"
      `sed 's/.*config_capistrano.*/config_capistrano production/g' #{command}`
    elsif @yml['environment'] == "staging"
      `sed 's/.*config_capistrano.*/config_capistrano staging/g' #{command}`
    else
      @errors.errors('environment')
      exit
    end
    exists = `cap #{ARGV[1]} createExists`
    exists_error if exists.chomp == "true"
    `cap #{ARGV[1]} setup`
    `cap #{ARGV[1]} sync`
    `cap #{ARGV[1]} git`
    Dir.chdir(@rails_root)
    `git init`
    `git remote add badger git@#{@yml['domain']}:/opt/git/#{ARGV[1]}.git`
    git_msg
  end

  def rake_tasks
    gem_setup
    arguments = ""
    ARGV[1..-1].each do |a|
      arguments << a << " "
    end
    Dir.chdir(@badger_root + "badger/")
    `cap rails-app rake -s brat=#{arguments.gsub!(" ", "^")}`
  end

  def scale(workers, app)
    gem_setup
    Dir.chdir(@badger_root + "badger/")
    app_claw = @badger_root + "badger/core/claws/"
    ensure_ssh
    `cap #{app} scale -s workers=#{workers}`
  end

  def update
    gem_setup
    Dir.chdir(@badger_root + "badger/")
    app_claw = @badger_root + "badger/core/claws/"
    ensure_ssh
    command = "#{app_claw}rails-app.claw > #{app_claw}app.tmp; mv #{app_claw}app.tmp #{app_claw}rails-app.claw"
    case @yml['redis']
    when true
      `sed 's/.*install_source_redis.*/install_source_redis/g' #{command}`
    when false
      `sed 's/.*install_source_redis.*/#install_source_redis/g' #{command}`
    else
      `sed 's/.*install_source_redis.*/#install_source_redis/g' #{command}`
    end

    if @yml['environment'] == "production"
      `sed 's/.*config_capistrano.*/config_capistrano production/g' #{command}`
    elsif @yml['environment'] == "staging"
      `sed 's/.*config_capistrano.*/config_capistrano staging/g' #{command}`
    else
      @errors.errors('environment')
      exit
    end
    exists = `cap #{ARGV[1]} exists`
    update_error if not exists.chomp == "true"
    `cap #{ARGV[1]} sync`
  end

  def update_error
    @errors.errors('update error')
    exit
  end

  def worker_server(app_claw, app)
    command = "#{app_claw}app.claw > #{app_claw}app.tmp; mv #{app_claw}app.tmp #{app_claw}app.claw"
    if @yml['environment'] == "production"
      `sed 's/.*config_capistrano.*/config_capistrano production-app #{app}/g' #{command}`
    elsif @yml['environment'] == "staging"
      `sed 's/.*config_capistrano.*/config_capistrano staging-app #{app}/g' #{command}`
    else
      @errors.errors('environment')
      exit
    end
    case @yml[app]['media']
    when true
      while true
        puts <<EOF

Badger-Rails does not provide licensing for the following installations. You will need to check your use case and compare to the following GPL licenses.
FFMPEG, X264, LAME, LIBMAD, LIBID3TAG, MADPLAY, SOX, FAAC, XVID

Do you wish to continue with ffmpeg installation? [ y/n ]

EOF
        response = STDIN.gets.chomp
        if response == "y"
          `sed 's/.*install_media_group.*/install_media_group/g' #{command}`
          break
        elsif response == "n"
          `sed 's/.*install_media_group.*/#install_media_group/g' #{command}`
          break
        end
      end
    when false
      `sed 's/.*install_media_group.*/#install_media_group/g' #{command}`
    else
      `sed 's/.*install_media_group.*/#install_media_group/g' #{command}`
    end
    `echo #{@yml['password']} > #{@badger_root}badger/core/files/ssh/app;
    echo #{@yml['domain']} >> #{@badger_root}badger/core/files/ssh/app;
    cap #{app} app_setup;
    cap #{app} app_sync;
    cap #{app} app_deploy`

    puts
    puts "Worker server deployed."
    puts
  end

end

class Core
  include Methods
end
