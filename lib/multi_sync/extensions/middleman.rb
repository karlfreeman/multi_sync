module MultiSync

  module Extensions

    class Middleman
      MultiSync.info "Middleman -v #{::Middleman::VERSION} auto-detected"

      class << self

        def source_dir
          File.expand_path(File.join(ENV['MM_ROOT'], 'build'))
        end

        def destination_dir
          ""
        end

      end

      MultiSync.source(:middleman, {
        type: :local,
        source_dir: MultiSync::Extensions::Middleman.source_dir
      })

    end

  end

end
