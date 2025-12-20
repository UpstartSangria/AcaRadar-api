# frozen_string_literal: true

require 'dry/monads'
require 'ostruct'
require_relative '../../infrastructure/utilities/logger'

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
module AcaRadar
  module Service
    class ListPapers
      include Dry::Monads::Result::Mixin

      PER_PAGE  = 10
      MAX_FETCH = 10_000

      # --- Public API ---------------------------------------------------------
      def call(journals:, page:, research_embedding: nil)
        page     = [page.to_i, 1].max
        per_page = PER_PAGE

        # ---- Debug: inputs ---------------------------------------------------
        AcaRadar.logger.debug(
          "ListPapers: journals=#{journals.inspect} page=#{page} " \
          "research_embedding_class=#{research_embedding.class} len=#{research_embedding&.length}"
        )

        # Fetch all papers first so sorting is correct
        all_papers = AcaRadar::Repository::Paper.find_by_categories(journals, limit: MAX_FETCH, offset: 0)
        total      = all_papers.length
        total_pages = (total.to_f / per_page).ceil

        # If we have a valid research embedding, compute scores and sort
        if valid_research_embedding?(research_embedding)
          research = research_embedding.map(&:to_f)

          AcaRadar.logger.debug(
            "ListPapers: research_embedding stats " \
            "dims=#{research.length} finite=#{all_finite?(research)} " \
            "norm=#{vector_norm(research)}"
          )

          computed = 0
          skipped_empty = 0
          skipped_dim = 0
          skipped_nonfinite = 0
          skipped_zero = 0

          skipped_samples = {
            empty: [],
            dim: [],
            nonfinite: [],
            zero: []
          }

          dim = research.length

          all_papers.each do |paper|
            emb = paper.embedding

            # Default to nil unless we can compute it
            paper.similarity_score = nil

            unless emb.is_a?(Array) && !emb.empty?
              skipped_empty += 1
              skipped_samples[:empty] << paper.title if skipped_samples[:empty].length < 3
              next
            end

            if emb.length != dim
              skipped_dim += 1
              skipped_samples[:dim] << "#{paper.title} (paper_dim=#{emb.length}, ri_dim=#{dim})" if skipped_samples[:dim].length < 3
              next
            end

            emb_f = emb.map(&:to_f)

            unless all_finite?(emb_f)
              skipped_nonfinite += 1
              skipped_samples[:nonfinite] << paper.title if skipped_samples[:nonfinite].length < 3
              next
            end

            if vector_norm(emb_f).zero? || vector_norm(research).zero?
              skipped_zero += 1
              skipped_samples[:zero] << paper.title if skipped_samples[:zero].length < 3
              next
            end

            score = AcaRadar::Service::CalculateSimilarity.score(research, emb_f)

            if score.nil? || !score.finite?
              skipped_nonfinite += 1
              skipped_samples[:nonfinite] << "#{paper.title} (score=#{score.inspect})" if skipped_samples[:nonfinite].length < 3
              paper.similarity_score = nil
              next
            end

            paper.similarity_score = score.to_f
            computed += 1
          end

          # Sort descending by computed similarity (nil scores sink to bottom)
          all_papers.sort_by! { |p| -(p.similarity_score || -1.0) }

          # ---- Debug: scoring summary ----------------------------------------
          scores = all_papers.map(&:similarity_score).compact
          min_s  = scores.min
          max_s  = scores.max
          mean_s = scores.empty? ? nil : (scores.sum / scores.length.to_f)

          top5 = all_papers.first(5).map { |p| [p.title, p.similarity_score] }

          AcaRadar.logger.debug(
            "ListPapers: similarity computed=#{computed}/#{total} " \
            "skipped_empty=#{skipped_empty} skipped_dim=#{skipped_dim} " \
            "skipped_nonfinite=#{skipped_nonfinite} skipped_zero=#{skipped_zero} " \
            "score_min=#{min_s} score_max=#{max_s} score_mean=#{mean_s}"
          )
          AcaRadar.logger.debug("ListPapers: Top 5 scores: #{top5.inspect}")

          if skipped_empty.positive? || skipped_dim.positive? || skipped_nonfinite.positive? || skipped_zero.positive?
            AcaRadar.logger.debug(
              "ListPapers: skipped samples " \
              "empty=#{skipped_samples[:empty].inspect} " \
              "dim=#{skipped_samples[:dim].inspect} " \
              "nonfinite=#{skipped_samples[:nonfinite].inspect} " \
              "zero=#{skipped_samples[:zero].inspect}"
            )
          end
        else
          AcaRadar.logger.debug(
            "ListPapers: no usable research embedding; returning unsorted page " \
            "(class=#{research_embedding.class} len=#{research_embedding&.length})"
          )
          # Ensure similarity_score is nil so representer renders null cleanly
          all_papers.each { |p| p.similarity_score = nil if p.respond_to?(:similarity_score=) }
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
        AcaRadar.logger.error(
          "Service::ListPapers failed: #{e.class} - #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}"
        )
        Failure(e)
      end

      # --- Helpers ------------------------------------------------------------
      def valid_research_embedding?(vec)
        vec.is_a?(Array) &&
          !vec.empty? &&
          vec.all? { |x| numeric_like?(x) } &&
          all_finite?(vec.map(&:to_f))
      rescue StandardError
        false
      end

      def numeric_like?(x)
        Float(x)
        true
      rescue StandardError
        false
      end

      def all_finite?(arr)
        arr.all? { |x| x.is_a?(Numeric) && x.finite? }
      end

      def vector_norm(arr)
        # sqrt(sum(x^2))
        sum_sq = 0.0
        arr.each do |v|
          f = v.to_f
          sum_sq += f * f
        end
        Math.sqrt(sum_sq)
      rescue StandardError
        0.0
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
