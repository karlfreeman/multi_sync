require "virtus"
require "multi_sync/mixins/log_helper"

module MultiSync

  # Defines constants and methods related to the Source
  class Source
    include Virtus
    include MultiSync::Mixins::LogHelper

    attribute :targets, Array, :default => []
    attribute :source_dir, String

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.targets.concat([*options.fetch(:targets, [])])
      raise(ArgumentError, "source_dir must be a present") unless options[:source_dir]
      self.source_dir = options.fetch(:source_dir).to_s
      self.source_dir << "/" unless self.source_dir.end_with?("/")
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