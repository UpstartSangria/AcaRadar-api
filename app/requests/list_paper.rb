# frozen_string_literal: true

module AcaRadar
  module Request
    # class that validate that 2 journals are selected and are different
    class ListPapers
      def initialize(params)
        @journal1 = params['journal1']&.strip
        @journal2 = params['journal2']&.strip
        @page     = [params['page']&.to_i || 1, 1].max
      end

      attr_reader :journal1, :journal2, :page

      def journals
        @journals ||= [journal1, journal2].compact_blank.uniq
      end

      def valid?
        journals.size == 2 && journal1 != journal2
      end

      def offset(limit = 10)
        (page - 1) * limit
      end
    end
  end
end
