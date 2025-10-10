module AcaRadar
  class Publication
    def initialize(publication_data)
      # hot fix: only return the first hash 
      @publication = publication_data.is_a?(Array) ? publication_data.first : publication_data
    end 

    def id 
      @id ||= @publication['id']
    end 

    def published
      @published ||= @publication['published']
    end 

    def updated
      @updated ||= @publication['updated']
    end 

    def links
      @links ||= @publication['links']
    end
  end 
end 