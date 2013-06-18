require "pathname"
require "digest/md5"
require "multi_sync/resource"

module MultiSync

  # Defines constants and methods related to the LocalResource
  class LocalResource < Resource

    # Initialize a new LocalResource object
    #
    # @param path [String]
    def initialize(options = {})
      self.path_with_root ||= options.delete(:with_root)
      self.path_without_root ||= options.delete(:without_root)
    end

    #
    def body
      File.read(self.path_with_root)
    end

    #
    def content_length
      File.size(self.path_with_root)
    end

    #
    def etag
      Digest::MD5.hexdigest(self.body)
    end

  end

end