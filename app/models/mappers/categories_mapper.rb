# frozen_string_literal: true

module AcaRadar
  # Categories Mapper Object
  class CategoriesMapper
    def initialize(hash)
      @hash = hash
    end

    def build_entity
      Categories.new(@hash['categories'], @hash['primary_category'])
    end
  end
end
