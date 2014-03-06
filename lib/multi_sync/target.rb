require 'fog'
require 'lazily'
require 'virtus'
require 'pathname'
require 'celluloid'
require 'multi_sync/attributes/pathname'
require 'multi_sync/mixins/log_helper'

module MultiSync
  class Target
    include Celluloid
    include Virtus.model
    include MultiSync::Mixins::LogHelper

    attribute :target_dir, MultiSync::Attributes::Pathname, default: Pathname.new('')
    attribute :destination_dir, MultiSync::Attributes::Pathname, default: Pathname.new('')
    attribute :credentials, Hash, default: :default_credentials

    def default_credentials
      Marshal.load(Marshal.dump(MultiSync.credentials))
    end
  end
end
