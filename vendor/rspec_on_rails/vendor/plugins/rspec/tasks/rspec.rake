require 'spec/rake/spectask'

plugin_specs = FileList['vendor/plugins/**/spec/**/*_spec.rb']

desc 'Run all model and controller specs'
task :spec do
  Rake::Task["spec:models"].invoke      rescue got_error = true
  Rake::Task["spec:controllers"].invoke rescue got_error = true
  Rake::Task["spec:views"].invoke       rescue got_error = true
  unless plugin_specs.empty? 
    Rake::Task["spec:plugins"].invoke   rescue got_error = true
  end
  
  # not yet supported
  #if File.exist?("spec/integration")
  #  Rake::Task["spec:integration"].invoke rescue got_error = true
  #end

  raise "RSpec failures" if got_error
end

task :stats => "spec:statsetup"

namespace :spec do
  desc "Run the specs under spec/models"
  Spec::Rake::SpecTask.new(:models => "db:test:prepare") do |t|
    t.spec_files = FileList['spec/models/**/*_spec.rb']
  end

  desc "Run the specs under spec/controllers"
  Spec::Rake::SpecTask.new(:controllers => "db:test:prepare") do |t|
    t.spec_files = FileList['spec/controllers/**/*_spec.rb']
  end
  
  desc "Run the specs under spec/views"
  Spec::Rake::SpecTask.new(:views => "db:test:prepare") do |t|
    t.spec_files = FileList['spec/views/**/*_spec.rb']
  end
  
  unless plugin_specs.empty?
    desc "Run the specs under vendor/plugins"
    Spec::Rake::SpecTask.new(:plugins => "db:test:prepare") do |t|
      t.spec_files = plugin_specs
    end
  end

  desc "Print Specdoc for all specs"
  Spec::Rake::SpecTask.new('doc') do |t|
    t.spec_files = FileList[
      'spec/models/**/*_spec.rb',
      'spec/controllers/**/*_spec.rb',
      'spec/views/**/*_spec.rb',
      'vendor/plugins/**/spec/**/*_spec.rb'
    ]
    t.spec_opts = ["--format", "specdoc"]
  end

  desc "Setup specs for stats"
  task :statsetup do
    require 'code_statistics'
    ::STATS_DIRECTORIES << %w(Model\ specs spec/models)
    ::STATS_DIRECTORIES << %w(Controller\ specs spec/controllers)
    ::STATS_DIRECTORIES << %w(View\ specs spec/views)
    ::CodeStatistics::TEST_TYPES << "Model specs"
    ::CodeStatistics::TEST_TYPES << "Controller specs"
    ::CodeStatistics::TEST_TYPES << "View specs"
    ::STATS_DIRECTORIES.delete_if {|a| a[0] =~ /test/}
  end

  namespace :db do
    namespace :fixtures do
      desc "Load fixtures (from spec/fixtures) into the current environment's database.  Load specific fixtures using FIXTURES=x,y"
      task :load => :environment do
        require 'active_record/fixtures'
        ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
        (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'spec', 'fixtures', '*.{yml,csv}'))).each do |fixture_file|
          Fixtures.create_fixtures('spec/fixtures', File.basename(fixture_file, '.*'))
        end
      end
    end
  end
end
