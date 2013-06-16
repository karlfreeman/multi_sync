require "pathname"
require "digest/md5"
require "state_machine"
require "multi_sync/resource"

module MultiSync

  # Defines constants and methods related to the RemoteResource
  class RemoteResource < Resource

    attr_accessor :fog_file

    state_machine :state, :initial => :unknown do

      state :unknown do
      end

      state :available do
      end

      state :unavailable do
      end

    end

    # Initialize a new RemoteResource object
    #
    # @param path [String]
    def initialize(options = {})
      self.fog_file = options.delete(:fog_file)
      self.path_with_root ||= options.delete(:with_root)
      self.path_without_root ||= options.delete(:without_root)
      super() # initialize the state_machine
      determine_status
    end

    def body
      self.fog_file.body
    end

    def content_length
      self.fog_file.content_length
    end

    def etag
      begin
        self.fog_file.etag
      rescue NoMethodError # fog local files don't have an MD5 etag
        Digest::MD5.hexdigest(File.read(self.path_with_root))
      end
    end

    private

    def determine_status
      self.state = self.fog_file.nil? ? "unavailable" : "available"
    end

  end

end