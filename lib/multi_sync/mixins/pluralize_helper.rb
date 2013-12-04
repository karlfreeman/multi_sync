module MultiSync

  module Mixins

    module PluralizeHelper

      #
      def pluralize(n, singular, plural = nil, prefix = true)
        if n == 1
          (prefix ? '1 ' : '') + singular
        elsif plural
          (prefix ? "#{n} " : '') + plural
        else
          (prefix ? "#{n} " : '') + "#{singular}s"
        end
      end

    end

  end

end
