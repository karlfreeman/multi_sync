require 'multi_mime'
require 'multi_sync/resource'

module MultiSync
  class LocalResource < Resource

    def body
      File.read(path_with_root.to_s)
    rescue
      return nil
    end

    def determine_etag
      body.nil? ? nil : Digest::MD5.hexdigest(body)
    end

    def determine_mtime
      File.mtime(path_with_root.to_s)
    rescue
      return nil
    end

    def determine_content_type
      MultiMime.type_for_path(path_with_root.to_s)
    end

    def determine_content_length
      body.nil? ? 0 : Fog::Storage.get_body_size(body)
    end
  end
end
