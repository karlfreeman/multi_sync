require 'virtus'
require 'lazily'
require 'pathname'
require 'multi_sync/source'
require 'multi_sync/resources/local_resource'

module MultiSync
  # Defines constants and methods related to the LocalSource
  class LocalSource < Source
    extend Virtus

    attribute :include, String
    attribute :exclude, String

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.include = options.fetch(:include, '**/*')
      self.exclude = options.fetch(:exclude, nil)
      super(options)
    end

    def files
      files = []
      included_files = Dir.glob(source_dir + include)
      excluded_files = exclude.nil? ? [] : Dir.glob(source_dir + exclude)
      (included_files - excluded_files).lazily.each { |path|
        next if File.directory?(path)
        files << path_to_local_resource(path)
      }
      files
    end
  end
end
