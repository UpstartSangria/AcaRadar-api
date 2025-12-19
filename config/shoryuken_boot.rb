# frozen_string_literal: true

require 'fileutils'
require_relative '../app/infrastructure/utilities/logger'

ENV['RACK_ENV'] ||= 'development'
ENV['PYTHON_BIN'] ||= File.expand_path('../../.venv/bin/python', __dir__)

def env_blank?(k)
  ENV[k].nil? || ENV[k].strip.empty?
end

cache_root = File.expand_path('../tmp/hf_cache', __dir__)
FileUtils.mkdir_p(cache_root)

ENV['HF_HOME']            = cache_root if env_blank?('HF_HOME')
ENV['TRANSFORMERS_CACHE'] = cache_root if env_blank?('TRANSFORMERS_CACHE')
ENV['HF_HUB_CACHE']       = File.join(cache_root, 'hub') if env_blank?('HF_HUB_CACHE')
ENV['SENTENCE_TRANSFORMERS_HOME'] = File.join(cache_root, 'sentence_transformers') if env_blank?('SENTENCE_TRANSFORMERS_HOME')
ENV['EMBED_SERVICE_URL'] = "http://127.0.0.1:8001/embed"

require_relative 'environment'

# load app code
require_relative '../require_app'
require_app

# loads workers
require_relative '../app/workers/embed_research_interest_worker'

puts "[SHORYUKEN_BOOT] TRANSFORMERS_CACHE=#{ENV['TRANSFORMERS_CACHE'].inspect}"
AcaRadar.logger.debug(
  "BOOT python=#{ENV['PYTHON_BIN']} HF_HOME=#{ENV['HF_HOME']} TRANSFORMERS_CACHE=#{ENV['TRANSFORMERS_CACHE']}"
)

