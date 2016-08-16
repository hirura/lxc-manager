require "rspec/core/rake_task"
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

ActiveRecord::Base.configurations = YAML.load_file( 'config/database.yml' )
ActiveRecord::Base.establish_connection( :development )

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
