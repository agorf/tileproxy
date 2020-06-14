require 'fileutils'
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
  PATH_REGEX =
    %r{\A/+(?<service>\w+)/+(?<z>\d+)/+(?<x>\d+)/+(?<y>\d+)\.png\z}.freeze

  def call(env)
    req = Rack::Request.new(env)
    match = req.path.match(PATH_REGEX)

    if match.nil?
      data = 'Invalid request path. Valid format: /service/z/x/y.png'
      return [400, { 'Content-Type' => 'text/plain' }, [data]]
    end

    params = Hash[match.names.map(&:to_sym).zip(match.captures)]
    xyz = params.values_at(:x, :y, :z).map(&:to_i)
    params[:quadkey] = Quadkey.tile_to_quadkey(*xyz)
    service_name = params.delete(:service)
    service = SERVICES[service_name]

    if service.nil?
      data = %(Service "#{service_name}" not found. Valid services: #{SERVICES.keys.sort.join(', ')})
      return [404, { 'Content-Type' => 'text/plain' }, [data]]
    end

    service_params = service.symbolize_keys
    service_url = service_params.delete(:url)
    tile_url = service_url % service_params.merge(params)
    tile_path = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy', req.path)

    if File.exist?(tile_path)
      data = File.open(tile_path).read
      return [200, { 'Content-Type' => 'image/png' }, [data]]
    end

    begin
      handle = URI.open(tile_url)
    rescue OpenURI::HTTPError => e
      data = "#{service_name} service responded with #{e.message}"
      return [502, { 'Content-Type' => 'text/plain' }, [data]]
    end

    # Cache tile
    FileUtils.mkdir_p(File.dirname(tile_path))
    File.open(tile_path, 'wb') { |f| IO.copy_stream(handle, f) }
    handle.rewind

    status = handle.status[0].to_i

    [status, { 'Content-Type' => 'image/png' }, handle]
  end
end

run MapServer.new
