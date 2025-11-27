# frozen_string_literal: true

require 'rack'
require 'roda'
require 'ostruct'
require 'logger'

# rubocop:disable Metrics/BlockLength
module AcaRadar
  # class for applicatopm
  class App < Roda
    plugin :halt
    plugin :flash
    plugin :all_verbs
    plugin :json_parser
    plugin :sessions,
           secret: ENV.fetch('SESSION_SECRET', 'test_secret_at_least_64_bytes_long_for_security_purposes_in_production')
    
    APP_LOGGER = Logger.new(STDOUT)
    APP_LOGGER.level = Logger::VERBOSE

    route do |routing|
      response['Content-Type'] = 'application/json'

      routing.root do
        message = "AcaRadar API v1 at /api/v1/ in #{App.environment} mode"
        result = Response::ApiResult.new(status: :ok, message: message)
        response.status = result.http_status_code
        Representer::HttpResponse.new(result).to_json
      end

      routing.on 'api', 'v1' do
        # POST /api/v1/research_interest
        routing.on 'research_interest' do
          routing.post do
            APP_LOGGER.info("Received POST request to /api/v1/research_interest")
            APP_LOGGER.info("Request parameters (routing.params): #{routing.params.inspect}")
            request_obj = Request::EmbedResearchInterest.new(routing.params)
            APP_LOGGER.info("Initialized Request::EmbedResearchInterest with: #{request_obj.inspect}")

            unless request_obj.valid?
              APP_LOGGER.warn("Request::EmbedResearchInterest validation failed for term: '#{request_obj.term}'")
              response.status = 400
              return Response::BadRequest.new(
                Representer::Error.generic('Research interest must be a non-empty string')
              ).to_json
            end
            APP_LOGGER.info("Request::EmbedResearchInterest is valid. Term: '#{request_obj.term}'")

            result = Service::EmbedResearchInterest.new.call(term: request_obj.term)
            APP_LOGGER.info("Service::EmbedResearchInterest call result: #{result.inspect}")

            if result.failure?
              APP_LOGGER.error("Service::EmbedResearchInterest failed. Result: #{result.inspect}")
              response.status = 422
              return Representer::Error.generic('Failed to embed research interest').to_json
            end
            APP_LOGGER.info("Service::EmbedResearchInterest succeeded. Value: #{result.value!.inspect}")

            session[:research_interest_term] = request_obj.term
            session[:research_interest_2d]   = result.value!
            APP_LOGGER.info("Session updated with term: '#{request_obj.term}' and 2D vector: #{result.value!.inspect}")

            research_interest = OpenStruct.new(
              term: request_obj.term,
              vector_2d: result.value!
            )

            response.status = 201
            Response::Created.new(
              Representer::ResearchInterest.new(research_interest)
            ).to_json
          end
        end

        # GET /api/v1/papers
        routing.on 'papers' do
          routing.get do
            request_obj = Request::ListPapers.new(routing.params)

            unless request_obj.valid?
              message = if request_obj.journals.uniq.length < 2
                          'Please select two different journals'
                        else
                          'Invalid or unknown journals. Please use one of the allowed journals.'
                        end

              return Response::BadRequest.new(
                Representer::Error.generic(message)
              ).to_json
            end

            papers = AcaRadar::Repository::Paper.find_by_categories(
              request_obj.journals,
              limit: 10,
              offset: request_obj.offset(10)
            )
            total = AcaRadar::Repository::Paper.count_by_categories(request_obj.journals)

            response_obj = OpenStruct.new(
              research_interest_term: session[:research_interest_term],
              research_interest_2d: session[:research_interest_2d],
              journals: request_obj.journals,
              papers: OpenStruct.new(
                data: papers,
                pagination: {
                  current: request_obj.page,
                  total_pages: (total / 10.0).ceil,
                  total_count: total,
                  prev_page: request_obj.page > 1 ? request_obj.page - 1 : nil,
                  next_page: request_obj.page < (total / 10.0).ceil ? request_obj.page + 1 : nil
                }
              )
            )

            Representer::PapersPageResponse.new(response_obj).to_json
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
