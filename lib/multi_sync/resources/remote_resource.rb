require "pathname"
require "state_machine"
require "multi_sync/resource"

module MultiSync

  # Defines constants and methods related to the RemoteResource
  class RemoteResource < Resource

    attr_accessor :fog_file

    state_machine :state, :initial => :unknown do

      after_transition :on => :remove, :do => :remove_file

      state :unknown do
      end

      state :available do
      end

      state :unavailable do
      end

      state :removed do
      end

      event :remove do
        transition :available => :removed
      end

    end

    # Initialize a new RemoteResource object
    #
    # @param path [String]
    def initialize(options = {})
      self.fog_file = options.delete(:fog_file)
      self.path_with_root = options.delete(:with_root) { Pathname.new("") }
      self.path_without_root = options.delete(:without_root) { Pathname.new("") }
      super() # initialize the state_machine
      determine_status
    end

    private

    def remove_file
      self.fog_file.destroy
      self.fog_file = nil
    end

    def determine_status
      self.state = self.fog_file.directory.files.head(self.fog_file.key).nil? ? "unavailable" : "available"
    end

  end

end