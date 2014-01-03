require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'yard'
YARD::Rake::YardocTask.new

require 'rspec/core/rake_task'
desc 'Run all examples'
RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
desc 'Run rubocop'
Rubocop::RakeTask.new(:rubocop)

namespace :spec do

  desc 'Run specs with middleman'
  task :middleman do
    ENV['BUNDLE_GEMFILE'] = 'gemfiles/middleman-3.1.x.gemfile'
    Rake::Task['spec'].execute
  end

  desc 'Run specs with rails 3.2'
  task :rails_3_2 do
    ENV['BUNDLE_GEMFILE'] = 'gemfiles/rails-3.2.x.gemfile'
    Rake::Task['spec'].execute
  end

  desc 'Run specs with rails 4.0'
  task :rails_4_0 do
    ENV['BUNDLE_GEMFILE'] = 'gemfiles/rails-4.0.x.gemfile'
    Rake::Task['spec'].execute
  end

end

task default: :spec
task test: :spec
