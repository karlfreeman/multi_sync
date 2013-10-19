require "fog"
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
      super(options)
    end

    #
    def body
      begin
        File.read(self.path_with_root.to_s)
      rescue
        return nil
      end
    end

    #
    def determine_etag
      self.body.nil? ? nil : Digest::MD5.hexdigest(self.body)
    end

    #
    def determine_mtime
      begin
        File.mtime(self.path_with_root.to_s)
      rescue
        return nil
      end
    end

    #
    def determine_content_type
      MultiMime.type_for_path(self.path_with_root.to_s)
    end

    #
    def determine_content_length
      self.body.nil? ? 0 : Fog::Storage.get_body_size(self.body)
    end

  end

end