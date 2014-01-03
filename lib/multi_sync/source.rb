require 'virtus'
require 'multi_sync/mixins/log_helper'

module MultiSync

  class Source
    include Virtus
    include MultiSync::Mixins::LogHelper

    attribute :targets, Array, default: []
    attribute :source_dir, String
    attribute :source_options, Hash

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      targets.concat([*options.fetch(:targets, [])])
      raise(ArgumentError, 'source_dir must be a present') unless options[:source_dir]
      self.source_dir = options.fetch(:source_dir).to_s
      source_dir << '/' unless source_dir.end_with?('/')
      self.source_dir = Pathname.new(source_dir)
      self.source_options = options.fetch(:source_options, {})
    end

    private

    def path_to_local_resource(path, options = {})
      pathname = Pathname.new(path)
      MultiSync::LocalResource.new({
        with_root: pathname,
        without_root: pathname.relative_path_from(source_dir).cleanpath
      }.merge(options).merge(source_options))
    end


  end

end
