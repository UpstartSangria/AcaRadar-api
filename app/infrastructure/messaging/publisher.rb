# frozen_string_literal: true

require 'http'
require 'json'
require 'http'

module AcaRadar
  module Messaging
    # Publishes progress updates to a Faye channel
    class Publisher
      
      def initialize(config, request_id)
        @config = config
        @channel_id = "/research_interest/#{request_id}" 
      end

      # @param [String] status - e.g., 'processing', 'failed', 'completed'
      # @param [String] message - e.g., 'Embedding research interest...'
      # @param [Integer] percent - e.g., 25, 50, 100
      def publish(status:, message:, percent: nil, payload: {})
        faye_url = "#{@config.API_HOST}/faye" 
        
        data = { 
          status: status, 
          message: message, 
          percent: percent 
        }.merge(payload)

        AcaRadar::App::APP_LOGGER.debug "FAYE_PUBLISH: Posting to #{faye_url} on channel #{@channel_id}"

        HTTP.headers('Content-Type' => 'application/json')
            .post(faye_url, body: message_body(data))

      rescue HTTP::ConnectionError => e
        AcaRadar::App::APP_LOGGER.error "FAYE_ERROR: Server not found at #{faye_url}. Details: #{e.message}"
      rescue StandardError => e
        AcaRadar::App::APP_LOGGER.error "FAYE_ERROR: Generic failure. Details: #{e.message}"
      end

      private

      def message_body(data)
        {
          channel: @channel_id,
          data: data
        }.to_json
      end
    end
  end
end