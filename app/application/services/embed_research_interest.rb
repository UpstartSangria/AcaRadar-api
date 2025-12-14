# frozen_string_literal: true

require 'dry/monads'

module AcaRadar
  module Service
    # Service to embed a research interest term
    class EmbedResearchInterest
      include Dry::Monads::Result::Mixin

      def call(term:)
        concepts = Entity::Concept.extract_from(term)
        return Failure('No concepts extracted from research interest') if concepts.empty?

        concept_text = concepts.map(&:to_s).join(', ')
        embedding = Value::Embedding.embed_from(concept_text)

        two_dim_embedding = Value::TwoDimEmbedding.reduce_dimension_from(embedding.full_embedding)
        
        AcaRadar::App::APP_LOGGER.debug("RI raw term: #{term.inspect}")
        AcaRadar::App::APP_LOGGER.debug("RI concepts: #{concepts.map(&:to_s).inspect}")
        AcaRadar::App::APP_LOGGER.debug("RI concept_text: #{concept_text.inspect}")
        AcaRadar::App::APP_LOGGER.debug("RI emb dims: #{embedding.full_embedding.length}")  

        Success(
          term: term,
          embedding: embedding.full_embedding,
          vector_2d: two_dim_embedding.two_dim_embedding
        ) 
      rescue StandardError => e
        Failure("Failed to embed research interest: #{e.message}")
      end
    end
  end
end


