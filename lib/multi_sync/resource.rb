require "virtus"
require "pathname"

module MultiSync

  # Defines constants and methods related to the Resource
  class Resource
    include Virtus

    attribute :path_with_root, Pathname
    attribute :path_without_root, Pathname

    def hash
      self.path_without_root.hash
    end

    def ==(other)
      return self.path_without_root == other.path_without_root
    end
    alias :eql? :==

  end

end