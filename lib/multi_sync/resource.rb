require 'virtus'
require 'pathname'
require 'digest/md5'
require 'multi_sync/mixins/log_helper'

module MultiSync
  class Resource
    include Comparable
    include Virtus.model
    include MultiSync::Mixins::LogHelper

    attribute :path_with_root, Pathname
    attribute :path_without_root, Pathname

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
      type: String
    }, {
      name: :cache_control,
      type: String
    }, {
      name: :encryption,
      type: String
    }]

    AWS_ATTRIBUTES.each do |attribute_hash|
      send(:attribute, attribute_hash[:name], attribute_hash[:type], default: attribute_hash.fetch(:default_value, nil))
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
