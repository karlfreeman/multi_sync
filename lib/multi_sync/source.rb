require "securerandom"
require "pathname"
require "multi_sync/local_resource"

module MultiSync

  # Defines constants and methods related to the Source
  class Source

    # An array of valid keys in the options hash when configuring a `MultiSync::Source`
    VALID_OPTIONS_KEYS = [
      :source_id,
      :source_dir,
      :include,
      :exclude
    ].freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      # raise(ArgumentError, "source_dir must be a directory") unless options[:source_dir] && File.directory?(options[:source_dir])
      self.source_id = SecureRandom.uuid
      self.source_dir = options.delete(:source_dir)
      self.source_dir << "/" unless (self.source_dir[-1, 1] == "/") # append '/' to source_dir's without one
      self.source_dir = Pathname.new(self.source_dir)
      self.include = options.delete(:include) { "**/*" }
      self.exclude = options.delete(:exclude)
    end
    
    #
    def files
      files = []
      included_files = Dir.glob(self.source_dir + self.include)
      excluded_files = self.exclude.nil? ? [] : Dir.glob(self.source_dir + self.exclude)
      (included_files - excluded_files).each { |f| files << Pathname.new(f) }
      files.reject!{ |pathname| pathname.directory? }
      files.map!{ |pathname|
        MultiSync::LocalResource.new(
          :with_root => pathname,
          :without_root => pathname.relative_path_from(self.source_dir).cleanpath
        )
      }
      return files
    end

  end

end