module MultiSync

  module Extensions

    require 'multi_sync/extensions/rails/railtie' if defined? ::Rails::Railtie

    class Rails
      MultiSync.debug "Rails -v #{::Rails::VERSION::STRING} auto-detected"

      def self.source_dir
        ::Rails.root.join('public', ::Rails.application.config.assets.prefix.sub(/^\//, ''))
      end

    end

  end

end
