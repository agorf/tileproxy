#!/usr/bin/env rackup

require 'yaml'

require_relative 'lib/tileproxy/app'

services = YAML.safe_load(open('services.yml')).freeze

run Tileproxy::App.new(services)
