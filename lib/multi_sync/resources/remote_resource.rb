require 'pathname'
require 'digest/md5'
require 'multi_sync/resource'

module MultiSync
  class RemoteResource < Resource
    # Initialize a new RemoteResource object
    #
    # @param path [String]
    def initialize(options = {})
      self.file = options.fetch(:file, nil)
      super(options)
    end

    def body
      file.body
    end

    def determine_etag
      file.etag
    rescue NoMethodError # Fog::Storage::Local::File's don't have an etag method :(
      Digest::MD5.hexdigest(File.read(path_with_root))
    end

    def determine_mtime
      file.last_modified
    end

    def determine_content_type
      file.content_type
    end

    def determine_content_length
      file.content_length
    end
  end
end
