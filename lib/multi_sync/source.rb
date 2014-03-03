require 'virtus'
require 'pathname'
require 'lazily'
require 'multi_sync/mixins/log_helper'

module MultiSync
  class Source
    include Virtus
    include MultiSync::Mixins::LogHelper

    attribute :targets, Array, default: []
    attribute :source_dir, String
    attribute :source_options, Hash
    attribute :include, String
    attribute :exclude, String

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      fail(ArgumentError, 'source_dir must be a present') unless options[:source_dir]
      targets.concat([*options.fetch(:targets, [])])
      self.source_dir = options.fetch(:source_dir).to_s
      source_dir << '/' unless source_dir.end_with?('/')
      self.source_dir = Pathname.new(source_dir)
      self.include = options.fetch(:include, '**/*')
      self.exclude = options.fetch(:exclude, nil)
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
