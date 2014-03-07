require 'fog'
require 'lazily'
require 'virtus'
require 'pathname'
require 'celluloid'
require 'multi_sync/attributes/pathname'

module MultiSync
  class Target
    include Celluloid
    include Virtus.model

    attribute :target_dir, MultiSync::Attributes::Pathname, default: Pathname.new('')
    attribute :destination_dir, MultiSync::Attributes::Pathname, default: Pathname.new('')
    attribute :credentials, Hash, default: :default_credentials

    def default_credentials
      Marshal.load(Marshal.dump(MultiSync.credentials))
    end
  end
end
