# config.ru
# frozen_string_literal: true

require 'bundler/setup'
require 'rack/cache'
require 'redis'
require 'faye'
require 'rack/cors'
require 'fileutils'
require_relative 'require_app'
require_app

Faye::WebSocket.load_adapter('puma')
env = ENV.fetch('RACK_ENV', 'development')

use Rack::Cors do
  allow do
    origins 'localhost:9000', '127.0.0.1:9000', 'https://acaradar-app-3bd1e48033fd.herokuapp.com'
    resource '*',
             headers: :any,
             methods: %i[get post options]
  end
end

# IMPORTANT: mount Faye as middleware so /faye/client.js works
use Faye::RackAdapter, mount: '/faye', timeout: 25

# Cache only applies to requests that Faye doesn't intercept
if env == 'production'
  redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
  use Rack::Cache,
      verbose: true,
      metastore: "#{redis_url}/metastore",
      entitystore: "#{redis_url}/entitystore"
else
  FileUtils.mkdir_p('tmp/cache/meta')
  FileUtils.mkdir_p('tmp/cache/body')

  use Rack::Cache,
      verbose: true,
      metastore: 'file:tmp/cache/meta',
      entitystore: 'file:tmp/cache/body'
end

run AcaRadar::App.freeze.app
