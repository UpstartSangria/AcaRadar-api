# frozen_string_literal: true

module AcaRadar
  module Repository
    # Repository for Papers
    class Paper
      def self.find_by_origin_id(origin_id)
        db_record = Database::PaperOrm.first(origin_id:)
        rebuild_entity(db_record)
      end

      def self.find_many_by_ids(origin_ids)
        origin_ids.map { |origin_id| find_by_origin_id(origin_id) }.compact
      end

      def self.find_title(title)
        rebuild_entity Database::PaperOrm.first(title:)
      end

      def self.rebuild_entity(db_record)
        return nil unless db_record

        paper_entity = Entity::Paper.allocate

        paper_entity.instance_variable_set(:@origin_id, db_record.origin_id)
        paper_entity.instance_variable_set(:@title, db_record.title)
        paper_entity.instance_variable_set(:@published, db_record.published)
        paper_entity.instance_variable_set(:@links, [])

        paper_entity
      end

      def self.rebuild_many(db_records)
        db_records.map do |db_paper|
          Papers.rebuild_entity(db_paper)
        end
      end

      def self.db_find_or_create(entity)
        paper_info = entity.to_attr_hash
        Database::PaperOrm.find_or_create(origin_id: paper_info[:origin_id]) do |paper|
          paper.update(paper_info)
        end
      end
    end
  end
end
