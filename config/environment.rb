# frozen_string_literal: true

require 'roda'
require 'figaro'
require 'yaml'
require 'sequel'

module AcaRadar
  # Configuration for the App
  class App < Roda
    plugin :environments

    configure :development, :test do
      secrets_file = File.expand_path('config/secrets.yml')
      Figaro.application = Figaro::Application.new(
      environment:,
      path: secrets_file
      )
      Figaro.load
      def self.config = Figaro.env
      CONFIG = YAML.safe_load_file(secrets_file) if File.file?(secrets_file)
      ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    end

    configure :production do
      def self.config = ENV
    end

    @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    def self.db = @db # rubocop:disable Style/TrivialAccessors
  end
end
