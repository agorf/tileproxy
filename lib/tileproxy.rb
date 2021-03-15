require 'rack'
require 'yaml'

require_relative 'tileproxy/middleware/path_validator'
require_relative 'tileproxy/middleware/service_validator'
require_relative 'tileproxy/middleware/extension_validator'
require_relative 'tileproxy/middleware/tile_downloader'

module Tileproxy
  SERVICES = YAML.safe_load(open('services.yml')).freeze
  TILE_CACHE_PATH = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy')

  App = Rack::Builder.new do
    urls = SERVICES.keys.map { |name| "/#{name}/" }

    use Rack::Static, urls: urls, root: TILE_CACHE_PATH, cascade: true

    use Tileproxy::Middleware::PathValidator
    use Tileproxy::Middleware::ServiceValidator, SERVICES.keys
    use Tileproxy::Middleware::ExtensionValidator
    use Tileproxy::Middleware::TileDownloader

    run Rack::Static.new(nil, urls: urls, root: TILE_CACHE_PATH)
  end
end
