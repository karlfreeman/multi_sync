module MultiSync
  module Extensions
    require 'multi_sync/extensions/rails/railtie' if defined?(::Rails::Railtie)
    require 'multi_sync/extensions/rails/asset_sync'
    class Rails
      MultiSync.debug "Rails -v #{::Rails::VERSION::STRING} auto-detected"
      class << self
        def source_dir
          ::Rails.root.join('public', destination_dir)
        end

        def destination_dir
          ::Rails.application.config.assets.prefix.sub(/^\//, '')
        end
      end
    end
  end
end
