#!/usr/bin/env rackup

require 'yaml'

require_relative 'lib/tileproxy/app'

services = YAML.safe_load(open('services.yml')).freeze
tile_cache_path = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy')

run Tileproxy::App.new(services: services, tile_cache_path: tile_cache_path)
