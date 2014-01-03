module MultiSync
  module Environment
    # Retrieves the current MultiSync environment
    #
    # @return [String] the current environment
    def environment
      @environment ||= ENV['MULTI_SYNC_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end
    alias_method :env, :environment

    # Sets the current MultiSync environment
    #
    # @param [String|Symbol] env the environment symbol
    def environment=(e)
      @environment = e.to_s
    end
    alias_method :env=, :environment=

    # Determines if we are in a particular environment
    #
    # @return [Boolean] true if current environment matches, false otherwise
    def environment?(e)
      environment == e.to_s
    end
    alias_method :env?, :environment?

    # Create methods for the environment shorthands
    [:test, :development, :staging, :production].each do |e|
      # Determines if we are in a particular environment
      #
      # @return [Boolean] true if current environment matches, false otherwise
      define_method "#{e}?" do
        environment? e
      end
    end
  end
end
