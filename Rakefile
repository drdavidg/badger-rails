require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('badger-rails', '1.0.0') do |p|
  p.description    = "Badger-Rails makes use of Capistrano and Badger to create a configuration for easy deployment to a remote server.\nBadger-Rails deploys to CentOs 6+ automatically building nginx, mysql, and of course ruby."
  p.summary        = "Configuration for using Badger with Rails deployment."
  p.url            = "http://github.com/curiousminds/rails-badger"
  p.author         = "Nathan Kelley"
  p.email          = "nathan@curiousminds.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.dependencies = ["capistrano"]
  p.install_message = <<-eos

     .-.           `--
    hMMMms`     `omMMMd
    NMMMMMm.   `dMMMMMN`
  `-ydMMMMMd   hMMMMMmy:`
  hs  +NMMMM/ :MMMMMo  od
./h    -NMMMh sMMMN:    y/-
 dm`    :MMMm hMMM/     dm`
`/s`     oMMm dMMs      s/`
 :do.    `mMm dMN`    .+m/
   +d`    yMh yMh    `h+`
    .s    sMo +Mh    o-
     /+   dM- `Mm   /+
      +/ :Mh   yM+ :o
       +sNM:   -MNso
        /Nd     hM+
         .osmNmys-
            -:-`

eos
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
