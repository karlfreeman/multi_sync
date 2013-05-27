require "state_machine"
require "pathname"
require "multi_sync/resource"

module MultiSync

  # Defines constants and methods related to the LocalResource
  class LocalResource < Resource

    state_machine :state, :initial => :unknown do

      state :unknown do
      end

      state :available do
      end

      state :unavailable do
      end

    end

    # Initialize a new LocalResource object
    #
    # @param path [String]
    def initialize(options = {})
      self.path_with_root = options.delete(:with_root) { Pathname.new("") }
      self.path_without_root = options.delete(:without_root) { Pathname.new("") }
      super() # initialize the state_machine
      determine_status
    end

    private

    def determine_status
      self.state = self.path_with_root.exist? ? "available" : "unavailable"
    end

  end

end