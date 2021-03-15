require 'yaml'

module Tileproxy
  SERVICES = YAML.safe_load(open('services.yml')).freeze
  TILE_CACHE_PATH = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy')
end
