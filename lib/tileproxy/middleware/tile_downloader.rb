require 'fileutils'
require 'open-uri'

require_relative 'base_middleware'
require_relative '../service'
require_relative '../tile'

module Tileproxy
  module Middleware
    class TileDownloader < BaseMiddleware
      def initialize(app, services:, tile_cache_path:)
        @app = app
        @services = services
        @tile_cache_path = tile_cache_path
      end

      def call(env)
        service_name = env.fetch('tileproxy.service_name')
        service = Service.new(@services.fetch(service_name))

        path = env.fetch('tileproxy.path')
        x = path.fetch(:x).to_i
        y = path.fetch(:y).to_i
        z = path.fetch(:z).to_i
        tile = Tile.new(x, y, z, extension: path.fetch(:ext))

        begin
          remote_file = URI.open(service.tile_url(tile))
        rescue OpenURI::HTTPError => e
          return http_error(
            :bad_gateway,
            "#{service_name} service responded with #{e.message}"
          )
        rescue Net::OpenTimeout
          return http_error(
            :bad_gateway,
            "Request to #{service_name} timed out"
          )
        end

        if remote_file.content_type.to_s.split('/', 2)[0] != 'image'
          return http_error(
            :bad_gateway,
            "Remote file Content-Type #{remote_file.content_type} is not an image"
          )
        end

        content_type = env.fetch('tileproxy.request_content_type')

        if remote_file.content_type != content_type
          return http_error(
            :bad_request,
            "Remote file Content-Type #{remote_file.content_type} is not #{content_type}"
          )
        end

        if remote_file.size == 0
          return http_error(:bad_gateway, 'Remote file is empty')
        end

        # Cache tile
        tile_path = File.join(@tile_cache_path, service_name, tile.path)
        FileUtils.mkdir_p(File.dirname(tile_path))
        File.open(tile_path, 'wb') do |local_file|
          IO.copy_stream(remote_file, local_file)
        end

        @app.call(env)
      end
    end
  end
end
