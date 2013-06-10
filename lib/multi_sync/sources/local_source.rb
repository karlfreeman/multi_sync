require "virtus"
require "lazily"
require "pathname"
require "multi_sync/source"
require "multi_sync/resources/local_resource"

module MultiSync

  # Defines constants and methods related to the LocalSource
  class LocalSource < Source
    extend Virtus

    attribute :source_dir, String

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      cloned_options = Marshal.load(Marshal.dump(options)) # deep clone options
      # raise(ArgumentError, "source_dir must be a directory") unless options[:source_dir] && File.directory?(options[:source_dir])
      self.source_dir = cloned_options.delete(:source_dir) { "" }
      self.source_dir << "/" unless (self.source_dir[-1, 1] == "/") # append '/' to source_dir's without one
      self.source_dir = Pathname.new(self.source_dir)
      super(cloned_options)
    end

    #
    def files
      files = []
      included_files = Dir.glob(self.source_dir + self.include)
      excluded_files = self.exclude.nil? ? [] : Dir.glob(self.source_dir + self.exclude)
      (included_files - excluded_files).lazily.each { | path |
        pathname = Pathname.new(path)
        next if pathname.directory?
        files << MultiSync::LocalResource.new(
          :with_root => pathname,
          :without_root => pathname.relative_path_from(self.source_dir).cleanpath
        )
      }
      return files
    end

  end

end