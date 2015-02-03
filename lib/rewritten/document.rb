require 'active_support/inflector'

module Rewritten
  module Document
    include ActiveSupport::Inflector

    def path
      plural = ActiveSupport::Inflector.pluralize(self.class.to_s)
      resources = ActiveSupport::Inflector.underscore(plural)
      "/#{resources}/#{self.id}"
    end

    def rewritten_url
      return "" unless persisted? 
      Rewritten.get_current_translation(path)
    end

    def rewritten_url=(new_url)
      if !new_url.nil? && new_url != "" && new_url != rewritten_url
        Rewritten.add_translation(new_url, path)
      end
    end

    def rewritten_urls
      return [] unless persisted? 
      Rewritten.get_all_translations(path)
    end

    def has_rewritten_url?
      Rewritten.exist_translation_for?(path)
    end
    
    def remove_rewritten_urls
      Rewritten.remove_all_translations(path)
    end
    
  end
end
