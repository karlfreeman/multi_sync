require "multi_sync"

namespace :assets do
  desc "Synchronize assets"
  task :sync => :environment do
    MultiSync.sync
  end
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["assets:sync"].invoke if defined?(MultiSync) # run_on_precompile?
end

Rake::Task["assetpack:build"].enhance do
  Rake::Task["assets:sync"].invoke if defined?(MultiSync) # run_on_precompile?
end