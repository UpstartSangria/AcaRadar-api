# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module AcaRadar
  module Representer
    # class that represents a paper
    class Paper < Representer::Base
      property :origin_id
      property :title
      property :summary, as: :abstract
      property :pdf_url
      property :published_at, exec_context: :decorator
      property :primary_category, as: :category

      property :authors, exec_context: :decorator

      property :similarity_score,
               exec_context: :decorator,
               if: -> { options[:user_vector_2d] }

      def published_at
        represented.published_at.iso8601
      end

      def authors
        represented.authors.join(', ')
      end

      def similarity_score
        return nil unless represented.embedding_2d && options[:user_vector_2d]

        Service::CalculateSimilarity.score(
          options[:user_vector_2d],
          represented.embedding_2d
        )&.round(4)
      end
    end
  end
end
