# frozen_string_literal: true

require 'open-uri'
require 'quadkey'
require 'rack'
require 'yaml'

use Rack::ContentLength

class Hash
  def symbolize_keys
    each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
  end
end

class MapServer
  SERVICES = YAML.safe_load(open('services.yaml')).freeze

  # http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
  PATH_REGEX = %r{\A/(?<service>\w+)/(?<z>\d+)/(?<x>\d+)/(?<y>\d+)\.png\z}

  def call(env)
    req = Rack::Request.new(env)
    match = req.path.match(PATH_REGEX)

    if match
      params           = Hash[match.names.map(&:to_sym).zip(match.captures)]
      xyz              = params.values_at(:x, :y, :z).map(&:to_i)
      params[:quadkey] = Quadkey.tile_to_quadkey(*xyz)
      service_name     = params.delete(:service)
      service          = SERVICES[service_name]

      if service
        service_params = service.symbolize_keys
        service_url    = service_params.delete(:url)
        tile_url       = service_url % service_params.merge(params)

        begin
          handle       = open(tile_url)
          data         = handle.read
          status       = handle.status[0].to_i
          content_type = 'image/png'
        rescue OpenURI::HTTPError => e
          data         = e.message
          status       = e.io.status[0].to_i
          content_type = 'text/plain'
        end
      else
        data = %(Service "#{service_name}" not found. Valid services: #{SERVICES.keys.sort.join(', ')})
        status = 404
        content_type = 'text/plain'
      end
    else
      data = 'Invalid request path. Valid format: /service/z/x/y.png'
      status = 400
      content_type = 'text/plain'
    end

    [status, { 'Content-Type' => content_type }, [data]]
  end
end

run MapServer.new
