require 'fileutils'
require 'open-uri'
require 'rack/utils'

require_relative '../service'
require_relative '../tile'

module Tileproxy
  module Middleware
    class TileDownloader
      def initialize(app)
        @app = app
      end

      def call(env)
        service_name = env.fetch('SERVICE_NAME')
        service = Service.new(SERVICES.fetch(service_name))

        x, y, z = env.values_at('PATH_X', 'PATH_Y', 'PATH_Z').map(&:to_i)
        tile = Tile.new(x, y, z, extension: env.fetch('PATH_EXT'))

        begin
          remote_file = URI.open(service.tile_url(tile))
        rescue OpenURI::HTTPError => e
          return [
            Rack::Utils.status_code(:bad_gateway),
            { 'Content-Type' => 'text/plain' },
            ["#{service_name} service responded with #{e.message}"]
          ]
        end

        if remote_file.content_type.to_s.split('/', 2)[0] != 'image'
          return [
            Rack::Utils.status_code(:bad_gateway),
            { 'Content-Type' => 'text/plain' },
            ["Remote file Content-Type #{remote_file.content_type} is not an image"]
          ]
        end

        content_type = env.fetch('REQUEST_CONTENT_TYPE')

        if remote_file.content_type != content_type
          return [
            Rack::Utils.status_code(:bad_request),
            { 'Content-Type' => 'text/plain' },
            ["Remote file Content-Type #{remote_file.content_type} is not #{content_type}"]
          ]
        end

        if remote_file.size == 0
          return [
            Rack::Utils.status_code(:bad_gateway),
            { 'Content-Type' => 'text/plain' },
            ['Remote file is empty']
          ]
        end

        # Cache tile
        tile_path = File.join(TILE_CACHE_PATH, service_name, tile.path)
        FileUtils.mkdir_p(File.dirname(tile_path))
        File.open(tile_path, 'wb') do |local_file|
          IO.copy_stream(remote_file, local_file)
        end

        @app.call(env)
      end
    end
  end
end
