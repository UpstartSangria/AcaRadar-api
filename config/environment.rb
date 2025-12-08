# frozen_string_literal: true

require 'roda'
require 'figaro'
require 'yaml'
require 'sequel'
require 'rack/session'

module AcaRadar
  class App < Roda
    plugin :environments

    # ---------------------------
    # DEVELOPMENT ENVIRONMENT
    # ---------------------------
    configure :development do
      Figaro.application = Figaro::Application.new(
        environment:,
        path: File.expand_path('config/secrets.yml')  # dev uses secrets.yml
      )
      Figaro.load

      def self.config = Figaro.env

      use Rack::Session::Cookie, secret: ENV.fetch('SESSION_SECRET')
      CONFIG = YAML.safe_load_file('config/secrets.yml')
      ENV['DATABASE_URL'] ||= "sqlite://#{config.DB_FILENAME}"
    end

    # ---------------------------
    # TEST ENVIRONMENT  (CI)
    # ---------------------------
    configure :test do
      # CI uses GitHub Action secrets
      def self.config = ENV

      use Rack::Session::Cookie, secret: ENV.fetch('SESSION_SECRET')
      ENV['DATABASE_URL'] ||= "sqlite://#{ENV['DB_FILENAME']}"
    end

    # ---------------------------
    # PRODUCTION (Heroku)
    # ---------------------------
    configure :production do
      def self.config = ENV

      use Rack::Session::Cookie, secret: ENV.fetch('SESSION_SECRET')
    end

    @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    def self.db = @db
  end
end
