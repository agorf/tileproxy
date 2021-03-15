require 'rack'

require_relative 'lib/tileproxy'
require_relative 'lib/tileproxy/map_server'

use(
  Rack::Static,
  urls: %w[/],
  root: Tileproxy::TILE_CACHE_PATH,
  cascade: true
)

use Rack::ContentLength

run Tileproxy::MapServer.new
