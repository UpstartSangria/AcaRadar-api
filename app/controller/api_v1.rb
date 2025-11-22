# frozen_string_literal: true

require 'rack'
require 'roda'

module AcaRadar
  # Web App
  class App < Roda
    plugin :halt
    plugin :flash
    plugin :all_verbs
    plugin :json_parser

    # rubocop:disable Metrics/BlockLength
    route do |routing|
      response['Content-Type'] = 'application/json'

      # GET /
      routing.root do
        message = "AcaRadar API v1 at /api/v1/ in #{App.environment} mode"

        result = Response::ApiResult.new(status: :ok, message: message)

        response.status = result.http_status_code
        Representer::HttpResponse.new(result).to_json
      end

      routing.on 'api', 'v1' do
        # POST /api/v1/research_interest
        routing.post 'research_interest' do
          request_obj = Request::EmbedResearchInterest.new(routing.params)

          unless request_obj.valid?
            error = Representer::Error.validation(term:
            { research_interest: 'must be a non-empty string with only letters, numbers, spaces, and hyphens' })
            response.status = 400
            return error.to_json
          end

          result = Service::EmbedResearchInterest.new.call(term: request_obj.term)

          if result.failure?
            error = Representer::Error.generic(result.failure)
            response.status = 422
            return error.to_json
          end

          session[:research_interest_term] = request_obj.term
          session[:research_interest_2d]   = result.value!

          representer = Representer::ResearchInterest.new(
            OpenStruct.new(term: request_obj.term, vector_2d: result.value!)
          )

          Response::Created.new(representer).tap { |r| response.status = r.status }.to_json
        end

        # GET /api/v1/papers
        routing.get 'papers' do
          request_obj = Request::ListPapers.new(routing.params)

          unless request_obj.valid?
            return Response::BadRequest.new(
              Representer::Error.generic('Please select two different journals')
            ).tap { |r| response.status = r.status }.to_json
          end

          papers = Repository::Paper.find_by_categories(
            request_obj.journals,
            limit: 10,
            offset: request_obj.offset(10)
          )

          total = Repository::Paper.count_by_categories(request_obj.journals)

          user_vector = session[:research_interest_2d]

          # Build the big response object
          response_obj = OpenStruct.new(
            research_interest_term: session[:research_interest_term],
            research_interest_2d: user_vector,
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

          # Pass user_vector to Paper representer via options
          Representer::PapersPageResponse.new(response_obj)
                                         .to_json(user_vector_2d: user_vector)
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
