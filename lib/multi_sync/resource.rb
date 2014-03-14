require 'virtus'
require 'pathname'
require 'digest/md5'

module MultiSync
  class Resource
    include Comparable
    include Virtus.model

    attribute :path_with_root, MultiSync::Attributes::Pathname
    attribute :path_without_root, MultiSync::Attributes::Pathname

    attribute :etag, String, default: :determine_etag, lazy: true
    attribute :mtime, Time, default: :determine_mtime, lazy: true
    attribute :content_length, Numeric, default: :determine_content_length, lazy: true
    attribute :content_type, String, default: :determine_content_type, lazy: true
    attribute :digest, String, default: ''

    AWS_ATTRIBUTES = [{
      name: :storage_class,
      type: String,
      default: 'STANDARD'
    }, {
      name: :acl,
      type: String,
      default: 'public-read'
    }, {
      name: :expires,
      type: String,
      required: false
    }, {
      name: :cache_control,
      type: String,
      required: false
    }, {
      name: :encryption,
      type: String,
      required: false
    }]

    AWS_ATTRIBUTES.each do |attribute_hash|
      def_attribute_hash = {}
      def_attribute_hash[:default] = attribute_hash[:default] unless attribute_hash[:default].nil?
      def_attribute_hash[:required] = attribute_hash[:required] unless attribute_hash[:required].nil?
      send(:attribute, attribute_hash[:name], attribute_hash[:type], def_attribute_hash)
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
    alias_method :eql?, :==

    def matching_etag?(other)
      etag == other.etag
    end
  end
end
