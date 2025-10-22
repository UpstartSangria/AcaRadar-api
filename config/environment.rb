# frozen_string_literal: true

require 'roda'
require 'figaro'
require 'yaml'
require 'sequel'

module AcaRadar
  # Configuration for the App
  class App < Roda
    plugin :environments

    Figaro.application = Figaro::Application.new(
      environment:,
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load
    def self.config = Figaro.env
    CONFIG = YAML.safe_load_file('config/secrets.yml')

    configure :development, :test do
      ENV['DATABASE_URL'] = "sqlite://#{config.DB_FILENAME}"
    end
    @db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    def self.db = @db # rubocop:disable Style/TrivialAccessors
  end
end
