module MultiSync
  module Extensions
    class Jekyll
      MultiSync.debug "Jekyll -v #{::Jekyll::VERSION} auto-detected"
      class << self
        def source_dir
          ''
        end

        def destination_dir
          ''
        end

        # def jekyll_site
        #   @jekyll_site ||= ::Jekyll::Site.new(jekyll_configuration)
        # end

        # def jekyll_configuration
        #   @jekyll_configuration ||= ::Jekyll.configuration
        # end
      end
    end
  end
end
