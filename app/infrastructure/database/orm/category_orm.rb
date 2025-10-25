# frozen_string_literal: true

module AcaRadar
  module Database
    # Object-Relational Mapper for Categories
    class CategoryOrm < Sequel::Model(:categories)
      one_to_many :paper_categories,
                  class: :'AcaRadar::Database::PaperCategoryOrm',
                  key: :category_id

      many_to_many :papers,
                   class: :'AcaRadar::Database::PaperOrm',
                   join_table: :paper_categories,
                   left_key: :category_id,
                   right_key: :paper_id

      plugin :timestamps, update_on_create: true

      def self.find_or_create(info)
        first(arxiv_name: info[:arxiv_name]) || create(info)
      end
    end
  end
end
