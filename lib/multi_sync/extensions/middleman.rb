module MultiSync
  module Extensions
    class Middleman
      MultiSync.debug "Middleman -v #{::Middleman::VERSION} auto-detected"
      class << self
        def source_dir
          File.expand_path(File.join(ENV['MM_ROOT'], 'build'))
        end

        def destination_dir
          ''
        end
      end
    end
  end
end
