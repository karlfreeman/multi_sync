require "pathname"
require "mime/types"
require "multi_mime"
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
      begin
        File.read(self.path_with_root.to_s)
      rescue
        return ""
      end
    end

    #
    def content_length
      begin
        File.size(self.path_with_root.to_s)
      rescue
        return 0
      end
    end

    #
    def content_type
      ::MIME::Types.type_for(self.path_with_root.to_s).first
      # MultiMime.type_for_path(self.path_with_root.to_s)
    end

    #
    def etag
      self.body.empty? ? "" : Digest::MD5.hexdigest(self.body)
    end

  end

end