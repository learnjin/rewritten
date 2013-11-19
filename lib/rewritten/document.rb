module Rewritten
  module Document

    def rewritten_url=(new_translation)
      Rewritten.add_translation(new_translation, url_for(self)) 
    end

    def rewritten_url
      return "" unless persisted? 
      Rewritten.get_current_translation(url_for(self))
    end

    def rewritten_urls
      return [] unless persisted? 
      Rewritten.get_all_translations(url_for(self))
    end

    def has_rewritten_url?
      Rewritten.exist_translation_for?(url_for(self))
    end
    
    def remove_rewritten_urls
      Rewritten.remove_all_translations(url_for(self))
    end
    
  end
end
