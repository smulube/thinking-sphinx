require 'rubygems'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

desc "Run the specs under spec"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Run all feature-set configurations"
task :features do |t|
  databases = ENV['DATABASES'] || 'mysql,postgresql'
  databases.split(',').each do |database|
    puts   "rake features:#{database}"
    system "rake features:#{database}"
  end
end

namespace :features do
  def add_task(name, description)
    Cucumber::Rake::Task.new(name, description) do |t|
      t.cucumber_opts = "--format pretty features/*.feature DATABASE=#{name} --exclude features/thinking_sphinx"
    end
  end
  
  add_task :mysql,      "Run feature-set against MySQL"
  add_task :postgresql, "Run feature-set against PostgreSQL"
end

namespace :rcov do
  desc "Generate RCov reports"
  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rcov = true
    t.rcov_opts = [
      '--exclude', 'spec',
      '--exclude', 'gems',
      '--exclude', 'riddle',
      '--exclude', 'ruby',
      '--aggregate coverage.data'
    ]
  end
  
  def add_task(name, description)
    Cucumber::Rake::Task.new(name, description) do |t|
      t.cucumber_opts = "--format pretty features/*.feature DATABASE=#{name}"
      t.rcov = true
      t.rcov_opts = [
        '--exclude', 'spec',
        '--exclude', 'gems',
        '--exclude', 'riddle',
        '--exclude', 'features',
        '--aggregate coverage.data'
      ]
    end
  end
  
  add_task :mysql,      "Run feature-set against MySQL with rcov"
  add_task :postgresql, "Run feature-set against PostgreSQL with rcov"
  
  task :all do
    rm 'coverage.data' if File.exist?('coverage.data')
    rm 'rerun.txt'     if File.exist?('rerun.txt')
    
    Rake::Task['rcov:rspec'].invoke
    Rake::Task['rcov:mysql'].invoke
    Rake::Task['rcov:postgresql'].invoke
  end
end

desc "Build cucumber.yml file"
task :cucumber_defaults do
  steps = FileList["features/step_definitions/**.rb"].collect { |path|
    "--require #{path}"
  }.join(" ")
  
  File.open('cucumber.yml', 'w') { |f|
    f.write "default: \"--require features/support/env.rb #{steps}\"\n"
  }
end
