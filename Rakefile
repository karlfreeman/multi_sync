require "bundler"
Bundler.setup
Bundler::GemHelper.install_tasks

require "yard"
YARD::Rake::YardocTask.new

require "rspec/core/rake_task"
desc "Run all examples"
RSpec::Core::RakeTask.new(:spec)

begin
  require "cane/rake_task"
  namespace :metric do
    desc "Analyze for code quality"
    Cane::RakeTask.new(:quality) do |cane|
      cane.abc_max = 27
      cane.no_doc = true
      cane.style_measure = 200
    end
  end
rescue LoadError
  warn "Cane is not available, metric:quality task not provided."
end

namespace :spec do

  desc "Run specs with middleman"
  task :middleman do
    ENV["BUNDLE_GEMFILE"] = "gemfiles/middleman-3.1.x.gemfile"
    Rake::Task["spec"].execute
  end

  desc "Run specs with rails"
  task :rails do
    ENV["BUNDLE_GEMFILE"] = "gemfiles/rails-3.2.x.gemfile"
    Rake::Task["spec"].execute
  end

end

task :default => :spec
task :test => :spec