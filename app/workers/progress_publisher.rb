# app/lib/faye/progress_publisher.rb

require 'http'

module AcaRadar
  module Faye
    # Publishes progress updates to a Faye channel
    class ProgressPublisher
      def initialize(config, channel_id)
        @config = config
        @channel_id = "/#{channel_id}"
      end

      # Publishes a structured message to the Faye channel
      # @param [String] status - e.g., 'processing', 'failed', 'completed'
      # @param [String] message - e.g., 'Embedding research interest...'
      # @param [Integer] progress - e.g., 25, 50, 100
      def publish(status:, message:, progress: nil)
        faye_url = "#{@config.API_HOST}/faye"
        payload = { status: status, message: message, progress: progress }

        App.logger.info "FAYE_PUBLISH: Posting to #{faye_url} on channel #{@channel_id}"

        HTTP.headers('Content-Type' => 'application/json')
            .post(faye_url, body: message_body(payload))

      rescue HTTP::ConnectionError => e
        App.logger.error "FAYE_ERROR: Server not found at #{faye_url} - progress not sent. Details: #{e.message}"
      end

      private

      # Constructs the full message body required by Faye's Rack adapter
      def message_body(payload)
        {
          channel: @channel_id,
          data: payload
        }.to_json
      end
    end
  end
end