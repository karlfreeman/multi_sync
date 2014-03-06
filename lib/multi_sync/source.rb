require 'virtus'
require 'pathname'
require 'lazily'
require 'multi_sync/attributes/pathname'
require 'multi_sync/resources/local_resource'

module MultiSync
  class Source
    include Virtus.model

    attribute :source_dir, MultiSync::Attributes::Pathname

    attribute :targets, Array, default: []
    attribute :resource_options, Hash, default: {}
    attribute :include, String, default: '**/*'
    attribute :exclude, String, default: ''

    private

    def path_to_local_resource(path, options = {})
      pathname = Pathname.new(path)
      path_options = { path_with_root: pathname, path_without_root: pathname.relative_path_from(source_dir).cleanpath }
      MultiSync::LocalResource.new(path_options.merge(options).merge(resource_options))
    end
  end
end
