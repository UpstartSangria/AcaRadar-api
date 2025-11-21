# frozen_string_literal: true

require_relative 'research_interest'

module AcaRadar
  module Representer
    # class that represents the response of each page of papers
    class PapersPageResponse < Representer::Base
      property :research_interest,
               decorator: Representer::ResearchInterest,
               if: -> { represented.research_interest_term }

      property :journals, exec_context: :decorator

      property :papers, decorator: Representer::PapersCollection

      def journals
        represented.journals
      end
    end
  end
end
