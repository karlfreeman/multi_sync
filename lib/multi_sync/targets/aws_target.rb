require 'fog'
require 'lazily'
require 'pathname'
require 'multi_sync/target'
require 'multi_sync/resources/remote_resource'

module MultiSync
  class AwsTarget < Target
    # Initialize a new AwsTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(options)
      self.connection = ::Fog::Storage.new(credentials.merge(provider: :aws))
    end

    def files
      files = []

      directory = connection.directories.get(target_dir.to_s, prefix: destination_dir.to_s)
      return files if directory.nil?

      directory.files.lazily.each { |file|

        pathname = Pathname.new(file.key)

        # eg directory or overreaching AWS globbing
        next unless valid_path?(pathname)

        files << MultiSync::RemoteResource.new(
          file: file,
          with_root: target_dir + pathname, # pathname seems to already have the prefix (destination_dir)
          without_root: destination_dir != '' ? pathname.relative_path_from(destination_dir).cleanpath : pathname,
        )

      }

      files
    end

    def upload(resource)
      MultiSync.say_status :upload, resource.path_without_root.to_s
      MultiSync.debug "Upload #{resource.class_name}:'#{resource.path_without_root.to_s}' to #{class_name}:'#{File.join('/', target_dir + destination_dir)}'"
      directory = connection.directories.get(target_dir.to_s)
      return if directory.nil?

      upload_hash = {
        key: (destination_dir + resource.path_without_root).to_s,
        body: resource.body,
        content_type: resource.content_type,
        content_md5: Digest::MD5.base64digest(resource.body)
      }

      MultiSync::Resource::AWS_ATTRIBUTES.each do |attribute_hash|
        upload_hash[attribute_hash[:name]] = resource.send(attribute_hash[:name])
      end

      directory.files.create(upload_hash)

      resource
    end

    def delete(resource)
      MultiSync.say_status :upload, resource.path_without_root.to_s
      MultiSync.debug "Delete #{resource.class_name}:'#{resource.path_without_root.to_s}' from #{class_name}:'#{File.join('/', target_dir + destination_dir)}'"
      connection.delete_object(target_dir.to_s, (destination_dir + resource.path_without_root).to_s)
      resource
    end

    private

    # directory or overreaching AWS globbing
    def valid_path?(pathname)
      # directory
      return false if pathname.to_s =~ /\/$/

      # overreaching AWS globbing
      return false if !destination_dir.to_s.empty? && !(pathname.to_s =~ /^#{destination_dir.to_s}\//)

      #
      true
    end
  end
end
