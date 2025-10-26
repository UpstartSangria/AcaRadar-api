# frozen_string_literal: true

module AcaRadar
  module Repository
    # Repository for Papers
    class Paper
      def self.find_id(id)
        rebuild_entity Database::PaperOrm.first(id:)
      end

      def self.find_title(title)
        rebuild_entity Database::PaperOrm.first(title:)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        Entity::Paper.new(
          id: db_record.id,
          title: db_record.title,
          published: db_record.published,
          updated: db_record.updated,
          summary: db_record.summary,
          journal_ref: db_record.journal_ref
        )
      end

      def self.rebuild_many(db_records)
        db_records.map do |db_paper|
          Papers.rebuild_entity(db_paper)
        end
      end

      def self.db_find_or_create(entity)
        Database::PaperOrm.find_or_create(entity.to_attr_hash)
      end
    end
  end
end
