# frozen_string_literal: true

require 'yaml'
require 'minitest/autorun'
require 'minitest/rg'
require 'vcr'
require 'webmock'
require 'simplecov'
require 'sequel'

require_relative '../../app/infrastructure/arxiv/gateways/arxiv_api'
require_relative '../../helper/arxiv_api_parser'
require_relative '../../config/environment'

# require all files under orm folders
orm_files = Dir[File.join(__dir__, '../../app/infrastructure/database/orm/*.rb')]
orm_files.each do |file|
  require file
end

# reauire all repositories files under repo folders
repo_files = Dir[File.join(__dir__, '../../app/infrastructure/database/repositories/*.rb')]
repo_files.each do |file|
  require file
end

CONFIG = YAML.safe_load_file('config/secrets.yml', aliases: true)
CORRECT = YAML.safe_load_file('spec/fixtures/arxiv_results.yml', aliases: true)

CASSETTES_FOLDER = 'spec/fixtures/cassettes'
CASSETTE_FILE = 'arxiv_api'

SimpleCov.start
