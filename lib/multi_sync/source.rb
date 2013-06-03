module MultiSync

  # Defines constants and methods related to the Source
  class Source

    # An array of valid keys in the options hash when configuring a Source
    VALID_OPTIONS_KEYS = [
      :targets,
      :include,
      :exclude
    ].freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)

    # Initialize a new Source object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.targets = []
      self.targets << options.delete(:targets) { [] }
      self.targets.flatten!
      self.include = options.delete(:include) { "**/*" }
      self.exclude = options.delete(:exclude)
    end

  end

end