require "virtus"
require "pathname"

module MultiSync

  # Defines constants and methods related to the Resource
  class Resource
    include Virtus
    include Comparable

    attribute :file, File
    attribute :path_with_root, Pathname
    attribute :path_without_root, Pathname

    def hash
      self.path_without_root.hash
    end

    def <=>(other)
      self.path_without_root <=> other.path_without_root
    end

    def ==(other)
      self.path_without_root == other.path_without_root
    end
    alias :eql? :==

    def has_matching_etag?(other)
      self.etag == other.etag
    end

  end

end