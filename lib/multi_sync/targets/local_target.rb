require 'multi_sync/target'
require 'multi_sync/resources/remote_resource'

module MultiSync
  class LocalTarget < Target
    attribute :connection, Fog::Storage, lazy: true, default: lambda { |target, attribute|
      Fog::Storage.new(target.credentials.merge(provider: :local))
    }

    def files
      files = []

      directory = connection.directories.get(destination_dir.to_s)
      return files if directory.nil?

      directory.files.lazily.each { |file|
        pathname = Pathname.new(file.key)

        # directory
        next if pathname.directory?
        files << MultiSync::RemoteResource.new(
          file: file,
          path_with_root: target_dir + destination_dir + pathname,
          path_without_root: pathname
        )
      }

      files
    end

    def upload(resource)
      key = resource.path_without_root.to_s
      MultiSync.say_status :upload, key
      MultiSync.debug "Upload #{resource} '#{key}' to #{self} '#{File.join(connection.local_root, destination_dir)}'"
      directory = connection.directories.get(destination_dir.to_s)
      return if directory.nil?
      directory.files.create(key: key, body: resource.body)
      resource
    end

    def delete(resource)
      key = resource.path_without_root.to_s
      MultiSync.say_status :delete, key
      MultiSync.debug "Delete #{resource} '#{key}' from #{self} '#{File.join(connection.local_root, destination_dir)}'"
      connection.directories.get(destination_dir.to_s).files.get(key).destroy
      resource
    end

  end
end
