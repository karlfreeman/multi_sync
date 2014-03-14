require 'fog'
require 'virtus'
require 'pathname'
require 'celluloid'
require 'multi_sync/attributes/pathname'

module MultiSync
  class Target
    include Celluloid
    include Virtus.model(strict: true)

    attribute :target_dir, MultiSync::Attributes::Pathname
    attribute :destination_dir, MultiSync::Attributes::Pathname, default: Pathname.new('')
    attribute :credentials, Hash, default: :default_credentials

    def initialize(*args)
      super
    rescue Virtus::CoercionError => e
      raise ArgumentError, e.message
    end

    private

    def default_credentials
      Marshal.load(Marshal.dump(MultiSync.credentials))
    end
  end
end
