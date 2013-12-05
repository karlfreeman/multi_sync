module MultiSync

  module Extensions

    require 'multi_sync/extensions/rails/railtie' if defined?(::Rails::Railtie)
    require 'multi_sync/extensions/rails/asset_sync'

    class Rails
      MultiSync.debug "Rails -v #{::Rails::VERSION::STRING} auto-detected"

      def self.source_dir
        ::Rails.root.join('public', self.assets_prefix)
      end

      def self.assets_prefix
        ::Rails.application.config.assets.prefix.sub(/^\//, '')
      end

    end

  end

end
