require 'multi_sync'

namespace :assets do
  desc 'Synchronize assets'
  task sync: :environment do
    ActiveSupport::Notifications.instrument 'multi_sync.run' do
      MultiSync::Extensions::AssetSync.check_and_migrate
      MultiSync.run if MultiSync.run_on_build
    end
  end
end

if Rake::Task.task_defined?('assets:precompile:nondigest')
  Rake::Task['assets:precompile:nondigest'].enhance do
    Rake::Task['assets:sync'].invoke if defined?(MultiSync)
  end
else
  Rake::Task['assets:precompile'].enhance do
    Rake::Task['assets:sync'].invoke if defined?(MultiSync)
  end
end
