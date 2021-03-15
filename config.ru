require 'rack'

require_relative 'lib/tileproxy/map_server'

use Rack::ContentLength

run Tileproxy::MapServer.new
