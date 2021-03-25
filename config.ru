#!/usr/bin/env rackup

require 'yaml'

require_relative 'lib/tileproxy/app'

CONFIG_PATH = ENV.fetch('CONFIG_PATH', './services.yml')

services = YAML.safe_load(open(CONFIG_PATH)).freeze
tile_cache_path = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy')

run Tileproxy::App.new(services: services, tile_cache_path: tile_cache_path)
