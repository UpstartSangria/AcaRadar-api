# frozen_string_literal: true

require 'dry/monads'
require 'ostruct'

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module AcaRadar
  module Service
    # class for processing papers from repository and pagination
    class ListPapers
      include Dry::Monads::Result::Mixin

      PER_PAGE = 10

      def call(journals:, page:, research_embedding: nil)
        page     = [page.to_i, 1].max
        per_page = PER_PAGE
      
        # Fetch ALL matching papers first (needed for proper sort)
        all_papers = AcaRadar::Repository::Paper.find_by_categories(journals, limit: 10_000, offset: 0)
        total = all_papers.length
        total_pages = (total.to_f / per_page).ceil
      
        if research_embedding.is_a?(Array) && !research_embedding.empty?
          all_papers.each do |paper|
            score = AcaRadar::Service::CalculateSimilarity.score(research_embedding, paper.embedding)
            paper.instance_variable_set(:@similarity_score, score)
          end
      
          all_papers.sort_by! { |p| -(p.instance_variable_get(:@similarity_score) || 0.0) }
        end
      
        offset = (page - 1) * per_page
        papers = all_papers.slice(offset, per_page) || []
      
        result_obj = OpenStruct.new(
          papers: papers,
          pagination: {
            current: page,
            total_pages: total_pages,
            total_count: total,
            prev_page: page > 1 ? page - 1 : nil,
            next_page: page < total_pages ? page + 1 : nil
          }
        )    
        Success(result_obj)
      rescue StandardError => e
        AcaRadar::App::APP_LOGGER.error(
          "Service::ListPapers failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
        )
        Failure(e)
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
