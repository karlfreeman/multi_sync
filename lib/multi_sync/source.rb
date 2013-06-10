require "virtus"

module MultiSync

  # Defines constants and methods related to the Source
  class Source
    include Virtus

    attribute :targets, Array, :default => []
    attribute :include, String, :default => "**/*"
    attribute :exclude, String

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.targets << options.delete(:targets) { [] }
      self.targets.flatten!
      self.include ||= options.delete(:include)
      self.exclude = options.delete(:exclude)
    end

  end

end