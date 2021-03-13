require 'fileutils'
require 'open-uri'
require 'rack'
require 'yaml'

use Rack::ContentLength

class MapServer
  SERVICES = YAML.safe_load(open('services.yaml')).freeze
  TILE_CACHE_PATH = File.join(ENV.fetch('HOME'), '.cache', 'tileproxy')

  # http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
  PATH_REGEX =
    %r{\A/+(?<service>\w+)/+(?<z>\d+)/+(?<x>\d+)/+(?<y>\d+)\.\w+\z}.freeze

  HTTP_STATUS = {
    ok: 200,
    bad_request: 400,
    not_found: 404,
    bad_gateway: 502
  }.freeze

  attr_reader :params

  def call(env)
    req = Rack::Request.new(env)
    match = req.path.match(PATH_REGEX)

    if match.nil?
      return respond_with_message(
        :bad_request,
        'Invalid request path. Valid format: /service/z/x/y.ext'
      )
    end

    @params = Hash[match.names.map(&:to_sym).zip(match.captures)]

    if service.empty?
      return respond_with_message(
        :not_found,
        %(Service "#{service_name}" not found. Available services: #{SERVICES.keys.sort.join(', ')})
      )
    end

    extname = File.extname(req.path)
    content_type = Rack::Mime::MIME_TYPES[extname]

    if content_type.nil?
      return respond_with_message(
        :bad_request,
        "Unknown Content-Type for requested file extension #{extname}"
      )
    end

    if content_type.split('/', 2)[0] != 'image'
      return respond_with_message(
        :bad_request,
        "Non-image Content-Type #{content_type} for requested file extension #{extname}"
      )
    end

    tile_path = File.join(TILE_CACHE_PATH, req.path)

    if File.exist?(tile_path)
      data = File.open(tile_path).read
      return respond(:ok, content_type, [data])
    end

    begin
      remote_file = URI.open(tile_url)
    rescue OpenURI::HTTPError => e
      return respond_with_message(
        :bad_gateway,
        "#{service_name} service responded with #{e.message}"
      )
    end

    if remote_file.content_type.to_s.split('/', 2)[0] != 'image'
      return respond_with_message(
        :bad_gateway,
        "Remote file Content-Type #{remote_file.content_type} is not an image"
      )
    end

    if remote_file.content_type != content_type
      return respond_with_message(
        :bad_request,
        "Remote file Content-Type #{remote_file.content_type} is not #{content_type}"
      )
    end

    if remote_file.size == 0
      return respond_with_message(:bad_gateway, 'Remote file is empty')
    end

    # Cache tile
    FileUtils.mkdir_p(File.dirname(tile_path))
    File.open(tile_path, 'wb') do |local_file|
      IO.copy_stream(remote_file, local_file)
    end
    remote_file.rewind

    status = remote_file.status[0].to_i
    data = remote_file.read

    [status, { 'Content-Type' => remote_file.content_type }, [data]]
  end

  private def service_name
    params.fetch(:service)
  end

  private def service
    SERVICES.fetch(service_name, {}).
      transform_keys(&:to_sym).
      transform_values do |value|
        if value.is_a?(Array)
          value.sample
        else
          value
        end
      end
  end

  private def tile_url
    args = service.dup
    format = args.delete(:url)

    x, y, z = params.values_at(:x, :y, :z).map(&:to_i)
    args.merge!(
      x: x,
      y: y,
      z: z,
      quadkey: tile_to_quadkey(x, y, z)
    )

    sprintf(format, args)
  end

  private def tile_to_quadkey(x, y, z)
    z.downto(1).reduce([]) { |digits, i|
      digit = '0'.ord
      mask = 1 << i - 1
      digit += 1 if x & mask != 0
      digit += 2 if y & mask != 0
      digits << digit.chr
    }.join
  end

  private def respond(status, content_type, data)
    [HTTP_STATUS.fetch(status), { 'Content-Type' => content_type }, data]
  end

  private def respond_with_message(status, message)
    respond(status, 'text/plain', [message.chomp + "\n"])
  end
end

run MapServer.new
