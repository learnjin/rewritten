module Rewritten
  module Document


    def rewritten_url
      return "" unless persisted? 
      Rewritten.get_current_translation(polymorphic_url(self, :only_path => true))
    end

    def rewritten_url=(new_url)
      if !new_url.nil? && new_url != "" && new_url != rewritten_url
        Rewritten.add_translation(new_url, polymorphic_url(self, :only_path => true)) 
      end
    end

    def rewritten_urls
      return [] unless persisted? 
      Rewritten.get_all_translations(polymorphic_url(self, :only_path => true))
    end

    def has_rewritten_url?
      Rewritten.exist_translation_for?(polymorphic_url(self, :only_path => true))
    end
    
    def remove_rewritten_urls
      Rewritten.remove_all_translations(polymorphic_url(self, :only_path => true))
    end
    
  end
end
