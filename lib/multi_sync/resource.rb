module MultiSync

  # Defines constants and methods related to the Resource
  class Resource

    # An array of valid keys in the options hash when configuring a Resource
    VALID_OPTIONS_KEYS = [
      :path_with_root,
      :path_without_root
    ].freeze

    # Bang open the valid options
    attr_accessor(*VALID_OPTIONS_KEYS)

    def hash
      self.path_without_root.hash
    end

    def ==(other)
      return self.path_without_root == other.path_without_root
    end
    alias :eql? :==

  end

end