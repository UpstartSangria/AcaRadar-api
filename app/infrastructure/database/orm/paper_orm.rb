# frozen_string_literal: true

module AcaRadar
  module Database
    # Object-Relational Mapper for Papers
    class PaperOrm < Sequel::Model(:papers)
      one_to_many :paper_authors,
                  class: :'AcaRadar::Database::PaperAuthorOrm',
                  key: :paper_id

      one_to_many :paper_categories,
                  class: :'AcaRadar::Database::PaperCategoryOrm',
                  key: :paper_id

      many_to_many :authors,
                   class: :'AcaRadar::Database::AuthorOrm',
                   join_table: :paper_authors,
                   left_key: :paper_id,
                   right_key: :author_id

      many_to_many :categories,
                   class: :'AcaRadar::Database::CategoryOrm',
                   join_table: :paper_categories,
                   left_key: :paper_id,
                   right_key: :category_id

      plugin :timestamps, update_on_create: true

      def self.find_or_create(info)
        first(paper_id: info[:paper_id]) || create(info)
      end
    end
  end
end
