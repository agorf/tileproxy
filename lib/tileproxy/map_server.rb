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

    def call(path, service)
      extension = path.fetch(:ext)
      content_type = Rack::Mime::MIME_TYPES[extension.downcase]

      if content_type.nil?
        return respond_with_message(
          :bad_request,
          "Unknown Content-Type for requested file extension #{extension}"
        )
      end

      if content_type.split('/', 2)[0] != 'image'
        return respond_with_message(
          :bad_request,
          "Non-image Content-Type #{content_type} for requested file extension #{extension}"
        )
      end

      xyz = path.values_at(:x, :y, :z).map(&:to_i)
      tile = Tileproxy::Tile.new(*xyz, extension: extension)

      begin
        remote_file = URI.open(service.tile_url(tile))
      rescue OpenURI::HTTPError => e
        return respond_with_message(
          :bad_gateway,
          "#{service.name} service responded with #{e.message}"
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

    private def respond(status, content_type, data)
      [HTTP_STATUS.fetch(status), { 'Content-Type' => content_type }, data]
    end

    private def respond_with_message(status, message)
      respond(status, 'text/plain', [message.chomp + "\n"])
    end
  end
end
