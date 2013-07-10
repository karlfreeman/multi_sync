module MultiSync

  module Mixins

    module PluralizeHelper

      #
      def pluralize(n, singular, plural=nil)
        if n == 1
          "1 #{singular}"
        elsif plural
          "#{n} #{plural}"
        else
          "#{n} #{singular}s"
        end
      end

    end

  end

end