require 'fileutils'
require 'open-uri'

require_relative 'tile'

module Tileproxy
  class MapServer
    HTTP_STATUS = {
      ok: 200,
      bad_request: 400,
      not_found: 404,
      bad_gateway: 502
    }.freeze

    def call(env)
      service = fetch_service(env)

      x, y, z = env.values_at('PATH_X', 'PATH_Y', 'PATH_Z').map(&:to_i)
      tile = Tileproxy::Tile.new(x, y, z, extension: env.fetch('PATH_EXT'))

      begin
        remote_file = URI.open(service.tile_url(tile))
      rescue OpenURI::HTTPError => e
        return respond_with_message(
          :bad_gateway,
          "#{service.name} service responded with #{e.message}"
        )
      end

      content_type = env.fetch('REQUEST_CONTENT_TYPE')

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
      tile_path = File.join(TILE_CACHE_PATH, service.name, tile.path)
      FileUtils.mkdir_p(File.dirname(tile_path))
      File.open(tile_path, 'wb') do |local_file|
        IO.copy_stream(remote_file, local_file)
      end
      remote_file.rewind

      status = remote_file.status[0].to_i
      data = remote_file.read

      [status, { 'Content-Type' => remote_file.content_type }, [data]]
    end

    private def fetch_service(env)
      service_name = env.fetch('SERVICE_NAME')
      service_config = SERVICES.fetch(service_name)
      Service.new(service_name, service_config)
    end

    private def respond(status, content_type, data)
      [HTTP_STATUS.fetch(status), { 'Content-Type' => content_type }, data]
    end

    private def respond_with_message(status, message)
      respond(status, 'text/plain', [message.chomp + "\n"])
    end
  end
end
