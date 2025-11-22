# frozen_string_literal: true

require_relative 'base'

module AcaRadar
  module Request
    # class for listing papers from 2 different journals
    class ListPapers < Base
      def journals
        @journals ||= begin
          raw = params['journals'] || []

          # handle both array param (journals[]=X&journals[]=Y) and string (journals=A,B,C)
          values = raw.is_a?(Array) ? raw : raw.to_s.split(',')
          cleaned = values.map(&:to_s).map(&:strip).reject(&:empty?).uniq

          cleaned
        end
      end

      def page
        [params['page'].to_i, 1].max
      end

      def offset(default_per_page = 10)
        (page - 1) * default_per_page
      end

      def valid?
        journals.size == 2 && journals.uniq.size == 2
      end

      def error_message
        return 'Page must be a positive integer' if page < 1
        return 'You must select exactly two different journals' unless valid?
rob_card = Card.new()
rob_card.suit 
instance methods 
rob_card
        nil
      end
    end
  end
end
