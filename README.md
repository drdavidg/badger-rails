![Logo](https://github.com/curiousminds/badger-rails/raw/master/BadgerGit.png "Logo")
#**Badger Rails Gem**
Allows for deployment of Rails 3 project to a CentOS 6+ Red Hat 6+ or Ubuntu Server running Mysql and Nginx.<br>
Badger Rails deploys to a Cent Os server by Capistrano for ease of use and Bash for speed. Some of the packages it will build are listed below.

**[Watch our Screencast on youtube](http://www.youtube.com/watch?feature=player_embedded&v=ki0CL3D-Llk)**

* automake
* bison
* capistrano-ext
* curl
* gcc-c++
* gcc
* git
* libyaml
* libtool
* libxml2
* libxslt
* logrotate
* make
* mysql
* nginx
* readline
* ruby
* rubygems
* zlib

###**Requirements**
* Unix or Linux with ruby 1.8+
* Capistrano
* ssh key
* git
* Rails 3+ Project that works :)
* gem 'mysql2' in Gemfile
* gem 'unicorn' in Gemfile
* gem 'therubyracer' in Gemfile. This may require the gem libv8.
* CentOS 6+ server Red Hat 6+ server or Ubuntu 10.04, 11.04, 11.10

###**Installation**
* gem install badger-rails

###**Usage**

In your rails project run the command < badger generate yml > and fill out the config/badger.yml file that is generated.
* username: "typically root"
* password: "server password"
* domain: "domain or ip of the server"
* port: "ssh port usually port 22"
* redis: false #true will host redis locally
* environment: "production" # or "staging", development and testing are excluded.

Run the following commands.<br>
badger create (name of project)<br>
git add .<br>
git commit -m "first badger commit"<br>
git push badger master<br>
badger deploy<br>

###**Further commits**
Additional commits can be made with git. To deploy these new commits push the code using < git push badger master > and < badger deploy >.

### Additional Information
  [Badger-Rails](https://github.com/curiousminds/badger-rails/wiki/Badger-Rails)


### Licensing
Copyright © 2012 Curious Minds. All rights reserved
Badger-Rails is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Badger-Rails is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License (http://www.gnu.org/licenses/gpl.html) for more details.

You should have received a copy of the GNU General Public License (http://www.gnu.org/licenses/gpl.html) along with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Non-GPL Licenses are available for Commercial Purposes, Please contact licensing(at)curiousminds(dot)com for license details. If you want to use this program for commercial purposes and your code is closed-source, You MUST obtain this license. More License Details can be found in LICENSING file.

