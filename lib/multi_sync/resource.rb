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

    attribute :etag, String
    attribute :mtime, Time
    attribute :content_length, Numeric
    attribute :digest, String

    # Initialize a new Resource object
    #
    # @param options [Hash]
    def initialize(options = {})
      self.path_with_root ||= options.delete(:with_root)
      self.path_without_root ||= options.delete(:without_root)
      self.etag ||= options.delete(:etag) { self.determine_etag }
      self.mtime ||= options.delete(:mtime) { self.determine_mtime }
      self.content_length ||= options.delete(:content_length) { self.determine_content_length }
      self.digest ||= options.delete(:digest)
    end

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