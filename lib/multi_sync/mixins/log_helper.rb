module MultiSync

  module Mixins

    module LogHelper

      #
      def class_name
        self.class.name.split("::").last
      end

    end

  end

end