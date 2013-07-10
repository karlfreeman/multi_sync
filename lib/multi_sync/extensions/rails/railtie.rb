module MultiSync

  module Extensions

    class Railtie < Rails::Railtie
      
      railtie_name :multi_sync

      rake_tasks do
        load "tasks/multi_sync_rails.rake"
      end

    end

  end

end