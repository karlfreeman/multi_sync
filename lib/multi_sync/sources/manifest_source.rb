require 'yaml'
require 'multi_json'
require 'multi_sync/source'
require 'multi_sync/resources/local_resource'

module MultiSync
  class ManifestSource < Source
    def files
      files = []
      # create a local_resource from each file
      # making sure to skip any that do not match the include/exclude patterns
      manifest_hash.each { |key, value|
        path = source_dir + key
        next if !path.fnmatch?(include.to_s) || path.fnmatch?(exclude.to_s || '')
        file = path_to_local_resource(path, mtime: value['mtime'], digest: value['digest'], content_length: value['size'])
        files << file
      }
      files.sort
    end

    private

    def manifest_hash
      manifest_hash = {}
      # ::ActionView::Base has a shortcut to the manifest file
      # otherwise lets hunt down that manifest file!
      if defined?(::ActionView::Base) && ::ActionView::Base.respond_to?(:assets_manifest)
        manifest_hash = ::ActionView::Base.assets_manifest.files
      else
        manifest_path = Dir.glob(source_dir + 'manifest*.{json,yaml,yml}').max { |f| File.ctime(f) }
        manifest_hash = parse_manifest(manifest_path)
      end
      manifest_hash
    end

    def parse_manifest(manifest_path)
      manifest_hash = {}
      manifest_data = File.read(manifest_path)

      # manifest files can be YAML or JSON but Sprockets::Manifest isn't backwards compatible with that in mind :(
      case File.extname(manifest_path)
      when '.json'
        manifest_hash = MultiJson.load(manifest_data)
      when '.yml', '.yaml'
        manifest_hash = YAML.load(manifest_data)
      else
        fail ArgumentError, "Unknown manifest type: #{manifest_path}"
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

        manifest_hash = modified_manifest_hash

      end

      manifest_hash
    end
  end
end
