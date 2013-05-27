require "set"
require "multi_sync/source"
require "multi_sync/target"

module MultiSync

  # Defines constants and methods related to the Client
  class Client

    # Initialize a new Client object
    #
    # @param options [Hash]
    def initialize(options = {})
    end

    #
    def targets
      @targets ||= SortedSet.new
    end

    #
    def sources
      @sources ||= SortedSet.new
    end

  end

end