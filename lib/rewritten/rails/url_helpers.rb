module Rewritten
  module Rails
    module UrlHelper
      def url_for(options = nil)
        Rewritten.get_current_translation(super)
      end
    end
  end
end
