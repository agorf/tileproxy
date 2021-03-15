require 'rack'

require_relative 'lib/tileproxy'
require_relative 'lib/tileproxy/middleware/path_parser'
require_relative 'lib/tileproxy/middleware/service_loader'
require_relative 'lib/tileproxy/middleware/extension_validator'
require_relative 'lib/tileproxy/map_server'

use(
  Rack::Static,
  urls: %w[/],
  root: Tileproxy::TILE_CACHE_PATH,
  cascade: true
)

use Rack::ContentLength

use Tileproxy::Middleware::PathParser

use Tileproxy::Middleware::ServiceLoader

use Tileproxy::Middleware::ExtensionValidator

run Tileproxy::MapServer.new
