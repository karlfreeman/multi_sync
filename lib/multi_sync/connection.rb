require "fog"

module MultiSync

  class Connection

    # Initialize a new Connection object
    #
    # @param options [Hash]
    def initialize(options = {})
    end

    private

    # construct a fog storage connection
    def build_conection(options={})
      # Fog::Storage.new(options)
    end

  end
end