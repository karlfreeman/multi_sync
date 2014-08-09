require 'multi_sync/target'
require 'multi_sync/resources/remote_resource'

module MultiSync
  class LocalTarget < Target
    attribute :connection, Fog::Storage, lazy: true, default: lambda { |target, _|
      Fog::Storage.new(target.credentials.merge(provider: :local))
    }

    def files
      files = []

      directory = connection.directories.get(destination_dir.to_s)
      return files if directory.nil?

      directory.files.each { |file|
        pathname = Pathname.new(file.key)

        # directory
        next if pathname.directory?
        files << MultiSync::RemoteResource.new(
          file: file,
          path_with_root: target_dir + destination_dir + pathname,
          path_without_root: pathname
        )
      }

      files.sort
    end

    def upload(resource)
      # MultiSync.say_status :upload, resource.path_with_root
      MultiSync.debug "Upload #{resource} '#{resource.path_without_root}' to #{self} '#{File.join(connection.local_root, destination_dir)}'"
      directory = connection.directories.get(destination_dir.to_s)
      return if directory.nil?
      directory.files.create(key: resource.path_without_root.to_s, body: resource.body)
      resource
    end

    def delete(resource)
      # MultiSync.say_status :delete, resource.path_with_root
      MultiSync.debug "Delete #{resource} '#{resource.path_without_root}' from #{self} '#{File.join(connection.local_root, destination_dir)}'"
      connection.directories.get(destination_dir.to_s).files.get(resource.path_without_root.to_s).destroy
      resource
    end
  end
end
