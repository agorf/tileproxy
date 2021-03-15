require 'rack'
require 'yaml'

require_relative 'tileproxy/middleware/path_parser'
require_relative 'tileproxy/middleware/service_validator'
require_relative 'tileproxy/middleware/extension_validator'
require_relative 'tileproxy/middleware/tile_downloader'

module Tileproxy
  SERVICES = YAML.safe_load(open('services.yml')).freeze
  TILE_CACHE_PATH = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy')

  App = Rack::Builder.new do
    use Rack::Static, urls: ['/'], root: TILE_CACHE_PATH, cascade: true

    use Tileproxy::Middleware::PathParser
    use Tileproxy::Middleware::ServiceValidator
    use Tileproxy::Middleware::ExtensionValidator
    use Tileproxy::Middleware::TileDownloader

    run Rack::Static.new(nil, urls: ['/'], root: TILE_CACHE_PATH)
  end
end
