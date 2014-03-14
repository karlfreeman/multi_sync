require 'virtus'
require 'pathname'

module MultiSync
  module Attributes
    class Pathname < ::Virtus::Attribute
      def coerce(value)
        return ::Pathname.new(value) unless value.nil?
        value
      end

      def value_coerced?(value)
        value.is_a?(::Pathname)
      end

      def coercion_method
        :to_s
      end

      def primitive
        ::Pathname
      end
    end
  end
end
