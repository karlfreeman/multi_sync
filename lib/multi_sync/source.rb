require "virtus"

module MultiSync

  # Defines constants and methods related to the Source
  class Source
    include Virtus

    attribute :targets, Array, :default => []
    attribute :source_dir, String

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.targets.concat([*options.delete(:targets)])
      # raise(ArgumentError, "source_dir must be a directory") unless options[:source_dir] && File.directory?(options[:source_dir])
      self.source_dir = options.delete(:source_dir) { "" }
      self.source_dir = self.source_dir.to_s
      self.source_dir << "/" unless (self.source_dir[-1, 1] == "/") # append '/' to source_dir's without one
      self.source_dir = Pathname.new(self.source_dir)
    end

    private

    #
    def path_to_local_resource(path, options = {})
      pathname = Pathname.new(path)
      MultiSync::LocalResource.new({
        :with_root => pathname,
        :without_root => pathname.relative_path_from(self.source_dir).cleanpath
      }.merge(options))
    end


  end

end