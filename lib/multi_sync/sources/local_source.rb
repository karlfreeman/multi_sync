require 'multi_sync/source'
require 'multi_sync/resources/local_resource'

module MultiSync
  class LocalSource < Source
    def files
      files = []
      # create a local_resource from each file
      # making sure to skip any that do not match the include/exclude patterns
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
