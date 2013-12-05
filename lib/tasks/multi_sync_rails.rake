require 'multi_sync'

namespace :assets do
  desc 'Synchronize assets'
  task :sync => :environment do
    ActiveSupport::Notifications.instrument 'multi_sync.run' do
      MultiSync::Extensions::AssetSync.check_and_migrate
      MultiSync.run
    end
  end
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["assets:sync"].invoke if defined?(MultiSync) && MultiSync.run_on_build
end
