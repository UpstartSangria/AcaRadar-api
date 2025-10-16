# frozen_string_literal: true

require 'roda'
require 'slim'

module AcaRadar
  # Web App
  class App < Roda
    plugin :render, engine: 'slim', views: 'app/views'
    plugin :assets, css: 'style.css', path: 'app/views/assets'
    plugin :common_logger, $stderr
    plugin :halt

    route do |routing|
      routing.assets # load CSS
      response['Content-Type'] = 'text/html; charset=utf-8'

      # GET /
      routing.root do
        view 'home'
      end

      # GET /selected_journals
      routing.on 'selected_journals' do
        @journal1 = routing.params['journal1']
        @journal2 = routing.params['journal2']
        view 'selected_journals'
      end
    end
  end
end
