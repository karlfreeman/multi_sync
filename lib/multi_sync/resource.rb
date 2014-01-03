require 'virtus'
require 'pathname'
require 'multi_sync/mixins/log_helper'

module MultiSync

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
      name: :storage_class,
      type: String,
      default_value: 'STANDARD'
    }, {
      name: :acl,
      type: String,
      default_value: 'public-read'
    }, {
      name: :expires,
      type: String,
      default_value: nil
    }, {
      name: :cache_control,
      type: String,
      default_value: nil
    }, {
      name: :encryption,
      type: String,
      default_value: nil
    }]

    AWS_ATTRIBUTES.each do |attribute_hash|
      send(:attribute, attribute_hash[:name], attribute_hash[:type])
    end

    # Initialize a new Resource object
    #
    # @param options [Hash]
    def initialize(options = {})
      raise(ArgumentError, 'with_root must be present') unless options[:with_root]
      raise(ArgumentError, 'without_root must be present') unless options[:without_root]
      self.path_with_root = options.fetch(:with_root)
      self.path_without_root = options.fetch(:without_root)
      self.etag = options.fetch(:etag, determine_etag)
      self.mtime = options.fetch(:mtime, determine_mtime)
      self.content_length = options.fetch(:content_length, determine_content_length)
      self.content_type = options.fetch(:content_type, determine_content_type)
      self.digest = options.fetch(:digest, '')

      AWS_ATTRIBUTES.each do |attribute_hash|
        send("#{attribute_hash[:name]}=".to_sym, options.fetch(attribute_hash[:name], attribute_hash[:default_value]))
      end

    end

    def hash
      path_without_root.hash
    end

    def <=>(other)
      path_without_root <=> other.path_without_root
    end

    def ==(other)
      path_without_root == other.path_without_root
    end
    alias :eql? :==

    def has_matching_etag?(other)
      etag == other.etag
    end

  end

end
