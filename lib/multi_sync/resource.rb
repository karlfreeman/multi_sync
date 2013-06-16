require "virtus"
require "pathname"

module MultiSync

  # Defines constants and methods related to the Resource
  class Resource
    include Virtus
    include Comparable

    attribute :path_with_root, Pathname
    attribute :path_without_root, Pathname

    def hash
      self.path_without_root.hash
    end

    def <=>(other)
      self.path_without_root.to_s.reverse <=> other.path_without_root.to_s.reverse
    end

    def ==(other)
      self.path_without_root == other.path_without_root
    end
    alias :eql? :==

    def same?(other)
      # if (self.etag != other.etag)
        # MultiSync.log "#{self.etag} vs #{other.etag}"
        # MultiSync.log "#{self.path_with_root} / #{other.path_with_root}"
      # end
      self.etag == other.etag
    end

  end

end