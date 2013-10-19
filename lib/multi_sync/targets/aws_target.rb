require "fog"
require "lazily"
require "pathname"
require "multi_sync/target"
require "multi_sync/resources/remote_resource"

module MultiSync

  # Defines constants and methods related to the AwsTarget
  class AwsTarget < Target

    # Initialize a new AwsTarget object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(options)
      self.connection = ::Fog::Storage.new(self.credentials.merge(:provider => :aws))
    end

    #
    def files
      files = []

      directory = self.connection.directories.get(self.target_dir.to_s, :prefix => self.destination_dir.to_s)
      return files if directory.nil?

      directory.files.lazily.each { |file|

        pathname = Pathname.new(file.key)

        # eg directory or overreaching AWS globbing
        next unless valid_path?(pathname)

        files << MultiSync::RemoteResource.new(
          :file => file,
          :with_root => self.target_dir + pathname, # pathname seems to already have the prefix ( destination_dir )
          :without_root => (self.destination_dir != "") ? pathname.relative_path_from(self.destination_dir).cleanpath : pathname,
        )

      }

      return files
    end

    #
    def upload(resource)

      MultiSync.say_status :upload, resource.path_without_root.to_s
      MultiSync.debug "Upload #{resource.class_name}:'#{resource.path_without_root.to_s}' to #{self.class_name}:'#{File.join('/', self.target_dir + self.destination_dir)}'"
      directory = self.connection.directories.get(self.target_dir.to_s)
      return if directory.nil?

      upload_hash = {
        :key => (self.destination_dir + resource.path_without_root).to_s,
        :body => resource.body,
        :content_type => resource.content_type,
        :content_md5 => Digest::MD5.base64digest(resource.body)
      }

      MultiSync::Resource::AWS_ATTRIBUTES.each do |attribute_hash|
        upload_hash[attribute_hash[:name]] = resource.send(attribute_hash[:name])
      end

      directory.files.create(upload_hash)

      return resource

    end

    #
    def delete(resource)

      MultiSync.say_status :upload, resource.path_without_root.to_s
      MultiSync.debug "Delete #{resource.class_name}:'#{resource.path_without_root.to_s}' from #{self.class_name}:'#{File.join('/', self.target_dir + self.destination_dir)}'"
      self.connection.delete_object(self.target_dir.to_s, (self.destination_dir + resource.path_without_root).to_s)

      return resource

    end

    private


    # directory or overreaching AWS globbing
    def valid_path?(pathname)

      # directory
      return false if pathname.to_s =~ /\/$/

      # overreaching AWS globbing
      return false if !self.destination_dir.to_s.empty? && !(pathname.to_s =~ /^#{self.destination_dir.to_s}\//)

      #
      return true

    end

  end

end