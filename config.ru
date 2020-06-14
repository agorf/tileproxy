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
      remote_file = URI.open(tile_url)
    rescue OpenURI::HTTPError => e
      data = "#{service_name} service responded with #{e.message}"
      return [502, { 'Content-Type' => 'text/plain' }, [data]]
    end

    if remote_file.content_type.to_s.split('/', 2)[0] != 'image'
      data = "Remote file Content-Type #{remote_file.content_type} is not an image"
      return [502, { 'Content-Type' => 'text/plain' }, [data]]
    end

    if remote_file.size == 0
      data = 'Remote file is empty'
      return [502, { 'Content-Type' => 'text/plain' }, [data]]
    end

    # Cache tile
    FileUtils.mkdir_p(File.dirname(tile_path))
    File.open(tile_path, 'wb') do |local_file|
      IO.copy_stream(remote_file, local_file)
    end
    remote_file.rewind

    status = remote_file.status[0].to_i
    data = remote_file.read

    [status, { 'Content-Type' => 'image/png' }, [data]]
  end
end

run MapServer.new
