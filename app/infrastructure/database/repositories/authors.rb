# frozen_string_literal: true

module AcaRadar
  module Repository
    # Repository for Authors
    class Author
      def self.find_id(id)
        rebuild_entity Database::AuthorOrm.first(id:)
      end

      def self.find_name(name)
        rebuild_entity Database::AuthorOrm.first(name:)
      end

      def self.find_last_name(last_name)
        rebuild_entity Database::AuthorOrm.first(last_name:)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Author.new(
          id: db_record.id,
          name: db_record.name,
          first_name: db_record.first_name,
          last_name: db_record.last_name
        )
      end

      def self.rebuild_many(db_records)
        db_records.map do |db_author|
          Authors.rebuild_entity(db_author)
        end
      end

      def self.db_find_or_create(entity)
        Database::AuthorOrm.find_or_create(entity.to_attr_hash)
      end
    end
  end
end
