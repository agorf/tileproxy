require 'rack'

require_relative 'lib/tileproxy'
require_relative 'lib/tileproxy/middleware/path_parser'
require_relative 'lib/tileproxy/middleware/service_validator'
require_relative 'lib/tileproxy/middleware/extension_validator'
require_relative 'lib/tileproxy/middleware/tile_downloader'

use Rack::Static, urls: %w[/], root: Tileproxy::TILE_CACHE_PATH, cascade: true

use Tileproxy::Middleware::PathParser
use Tileproxy::Middleware::ServiceValidator
use Tileproxy::Middleware::ExtensionValidator
use Tileproxy::Middleware::TileDownloader

run Rack::Static.new(nil, urls: %w[/], root: Tileproxy::TILE_CACHE_PATH)
