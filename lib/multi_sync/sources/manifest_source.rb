require 'virtus'
require 'lazily'
require 'pathname'
require 'multi_json'
require 'multi_sync/source'
require 'multi_sync/resources/local_resource'

module MultiSync

  # Defines constants and methods related to the LocalSource
  class ManifestSource < Source
    extend Virtus

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      super(options)
    end

    #
    def files
      files = []
      manifest_hash = {}

      # ::ActionView::Base has a shortcut to the manifest file
      # otherwise lets hunt down that manifest file!
      if defined?(::ActionView::Base) && ::ActionView::Base.respond_to?(:assets_manifest)
        manifest_hash = ::ActionView::Base.assets_manifest.files
      else
        manifest_path = locate_manifest(source_dir)
        manifest_hash = parse_manifest(manifest_path)
      end

      # create a local_resource from each file
      manifest_hash.lazily.each { |key, value|
        files << path_to_local_resource(source_dir + key, {
          mtime: value['mtime'],
          digest: value['digest'],
          content_length: value['size']
        })
      }

      files
    end

    private

    #
    def locate_manifest(dir)
      Dir.glob(dir.to_s + 'manifest*.{json,yaml,yml}').max { |f| File.ctime(f) }
    end

    #
    def parse_manifest(manifest_path)
      manifest_hash = {}
      manifest_data = File.read(manifest_path)

      # manifest files can be YAML or JSON but Sprockets::Manifest isn't backwards compatible with that in mind :(
      case File.extname(manifest_path)
      when '.json'
        manifest_hash = MultiJson.load(manifest_data)
      when '.yml', '.yaml'
        manifest_hash = YAML.load(manifest_data)
      end

      # different versions of Sprockets have different manifest layouts, lets try and work around this by checking for the presence of "files" and "assets" in the manifest first
      # else we know it must be an old manifest file, so its root is "files"
      if manifest_hash.key?('files') || manifest_hash.key?('assets')
        manifest_hash = manifest_hash['files']
      else

        # index.* files are special and should be ignored from sync
        # something which seems to only happen in older versions of Sprockets
        manifest_hash.delete_if { |key, value|
          key.include?('/index.')
        }

        # lets manipulate this older manifest to appear similiar to the newer manifest's "files"
        modified_manifest_hash = {}
        manifest_hash.each { |key, value|
          modified_manifest_hash[value] = {
            'logical_path' => key,
            'mtime' => nil,
            'size' => nil,
            'digest' => nil
          }
        }

        #
        manifest_hash = modified_manifest_hash

      end

      manifest_hash

    end

  end

end
