# frozen_string_literal: true

module AcaRadar
  module Representer
    # class for the paper collections
    class PapersCollection < Representer::Base
      collection :data,
                 decorator: Representer::Paper,
                 class: Entity::Paper

      property :pagination do
        property :current
        property :total_pages
        property :total_count
        property :prev_page, as: :prev
        property :next_page, as: :next
      end
    end
  end
end
