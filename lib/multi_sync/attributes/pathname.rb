require 'virtus'
require 'pathname'

module MultiSync
  module Attributes
    class Pathname < ::Virtus::Attribute
      def coerce(value)
        ::Pathname.new(value)
      end
    end
  end
end
