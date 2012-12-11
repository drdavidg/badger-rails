module ErrorList

  def errors(error)
    case error
    when 'rails' #----------------
      puts <<EOF

There is no Rails project on this server.

EOF
    when 'scale int' #----------------
      puts <<EOF

Error: scale requiers an Integer value.
Usage: < badger [app#] scale [number_of_workers] >

EOF
    when 'scale' #----------------
      puts <<EOF

Error: did you mean scale?
Usage: < badger [app#] scale [#] >

EOF
    when 'app build' #----------------
      puts <<EOF

Error: did you mean build?
Usage: < badger [app#] build >

EOF
    when 'app usage' #----------------
      puts <<EOF

Usage:
< badger [app#] scale [#} >
< badger [app#] build >

EOF
    when 'name' #----------------
      puts <<EOF

Error: name of rails app is required.
Usage: badger create < name_of_rails_app >

EOF
    when 'specific name' #----------------
      puts <<EOF

Error: name of project cannot be < db > or start with < app >.

EOF
    when 'db build' #----------------
      puts <<EOF

Error: did you mean build?
Usage: badger db build

EOF
    when 'plugins' #----------------
      puts <<EOF

Error: Plugin already exists.

EOF
    when 'rails root' #----------------
      puts <<EOF

Error: could not locate rails application.
Enter the root of your rails application and try again.

EOF
    when 'badger yaml' #----------------
      puts <<EOF

Error: badger.yml already exists.

EOF
    when 'yaml exists' #----------------
      puts <<EOF

Error: could not locate badger.yml file.
A config/badger.yml file is required for server configuration.

EOF
    when 'environment' #----------------
      puts <<EOF

Error: no envirionment specified.
Please add an either staging or production to the config/badger.yml file.

EOF
    when 'generate plugins' #----------------
      puts <<EOF

Error: no generate specified.
Badger does not know what to generate. Did you mean plugins?

EOF
    when 'generate yaml' #----------------
      puts <<EOF

Error: no generate specified.
Badger does not know what to generate. Did you mean yml?

EOF
    when 'generate' #----------------
      puts <<EOF

Error: no gererate specified.
< badger generate yml >
< badger generate plugins >

EOF
    when 'gemset clear' #----------------
      puts <<EOF

Command not understood did you mean badger gemset clear?

EOF
    when 'usage' #----------------
      puts <<EOF

  Usage:
< badger create [project-name] >
< badger remove [project-name] >
< badger update [project-name] >
< badger deploy >
< badger deploy --with-workers >
< badger gemset clear >
< badger generate [generator] >
< badger rake [rake command] >
< badger db build >
< badger app[number] build >
< badger info >
< badger logs >
< badger logs tail >
  g, gen, generate - yml, plugins

EOF
    when 'rubyracer' #----------------
      puts <<EOF

Error: Gemfile is missing therubyracer.
Add therubyracter, :platform => :ruby to your Gemfile
and run bundle update.

EOF
    when 'mysql2' #----------------
      puts <<EOF

Error: Gemfile is missing mysql2 adapter.
Add mysql2 to your Gemfile and run bundle update.

EOF
    when 'unicorn' #----------------
      puts <<EOF

Error: Gemfile is missing unicorn.
Add unicorn to your Gemfile and run bundle update.

EOF
    when 'ssh' #----------------
      puts <<EOF

Error: no ssh key found.
Generate a ssh key via < ssh-keygen -t rsa >.

EOF
    when 'rails project' #----------------
      puts <<EOF

Rails project already exists.

EOF
    when 'info error' #----------------
      puts <<EOF

No Rails project found.

EOF
    when 'update error' #----------------
      puts <<EOF

Rails project #{ARGV[1]} was not found.

EOF
    when 'local db'
      puts <<EOF

Error: cannot deploy app withou local_db set to false.
Place local_db: false in your config/badger.yml

EOF
    end
  end

end

class Errors
  include ErrorList
end
