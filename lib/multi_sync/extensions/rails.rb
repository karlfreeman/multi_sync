module MultiSync

  module Extensions

    require "multi_sync/extensions/rails/railtie" if defined? ::Rails::Railtie

    class Rails
      MultiSync.info "Rails -v #{::Rails::VERSION::STRING} auto-detected"
    end

  end

end