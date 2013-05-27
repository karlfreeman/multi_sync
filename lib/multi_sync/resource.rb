require "pathname"

module MultiSync

  # Defines constants and methods related to the Resource
  class Resource

    attr_accessor :path_with_root, :path_without_root

    def hash
      self.path_without_root.hash
    end

    def ==(other)
      return self.path_without_root == other.path_without_root
    end
    alias :eql? :==

  end

end