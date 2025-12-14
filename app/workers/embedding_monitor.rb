# frozen_string_literal: true

module AcaRadar
  module Service
    # Defines progress stages and messages for the embedding process
    module EmbeddingMonitor
      # A lookup hash for progress stages, percentages, and messages
      PROGRESS_STAGES = {
        started:           { percent: 10,  message: 'Job received and is starting...' },
        contacting_api:    { percent: 25,  message: 'Contacting external API...' },
        embedding:         { percent: 50,  message: 'Embedding research interest...' },
        reducing_dimensions: { percent: 75,  message: 'Reducing dimensions...' },
        completed:         { percent: 100, message: 'Successfully embedded interest.' },
        failed:            { percent: 100, message: 'An error occurred during embedding.' }
      }.freeze

      # Helper method to get the details for a specific stage
      def self.stage_details(stage, overrides = {})
        PROGRESS_STAGES[stage].merge(overrides)
      end
    end
  end
end