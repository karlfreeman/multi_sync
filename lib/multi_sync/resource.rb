require "virtus"
require "pathname"
require "multi_sync/mixins/log_helper"

module MultiSync

  # Defines constants and methods related to the Resource
  class Resource
    include Virtus
    include Comparable
    include MultiSync::Mixins::LogHelper

    attribute :file, File
    attribute :path_with_root, Pathname
    attribute :path_without_root, Pathname

    attribute :etag, String
    attribute :mtime, Time
    attribute :content_length, Numeric
    attribute :content_type, String
    attribute :digest, String

    AWS_ATTRIBUTES = [{
      :name => :storage_class,
      :type => String,
      :default_value => "STANDARD"
    },{
      :name => :acl,
      :type => String,
      :default_value => "public-read"
    },{
      :name => :expires,
      :type => Numeric,
      :default_value => nil
    },{
      :name => :encryption,
      :type => String,
      :default_value => nil
    }].freeze

    AWS_ATTRIBUTES.each do |attribute_hash|
      self.send(:attribute, attribute_hash[:name], attribute_hash[:type])
    end

    # Initialize a new Resource object
    #
    # @param options [Hash]
    def initialize(options = {})
      raise(ArgumentError, "with_root must be present") unless options[:with_root]
      raise(ArgumentError, "without_root must be present") unless options[:without_root]
      self.path_with_root = options.fetch(:with_root)
      self.path_without_root = options.fetch(:without_root)
      self.etag = options.fetch(:etag, self.determine_etag)
      self.mtime = options.fetch(:mtime, self.determine_mtime)
      self.content_length = options.fetch(:content_length, self.determine_content_length)
      self.content_type = options.fetch(:content_type, self.determine_content_type)
      self.digest = options.fetch(:digest, "")

      AWS_ATTRIBUTES.each do |attribute_hash|
        self.send("#{attribute_hash[:name]}=".to_sym, options.fetch(attribute_hash[:name], attribute_hash[:default_value]))
      end

    end

    #
    def hash
      self.path_without_root.hash
    end

    #
    def <=>(other)
      self.path_without_root <=> other.path_without_root
    end

    #
    def ==(other)
      self.path_without_root == other.path_without_root
    end
    alias :eql? :==

    #
    def has_matching_etag?(other)
      self.etag == other.etag
    end

  end

end