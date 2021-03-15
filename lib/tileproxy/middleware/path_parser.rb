require 'rack/utils'

module Tileproxy
  module Middleware
    class PathParser
      # http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
      PATH_REGEX = %r{
        \A
        /+(?<service>\w+)
        /+(?<z>\d+)
        /+(?<x>\d+)
        /+(?<y>\d+)
        (?<ext>\.[A-Za-z]+)
        \z
      }x.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        req = Rack::Request.new(env)
        match = req.path.match(PATH_REGEX)

        if match.nil?
          return [
            Rack::Utils.status_code(:bad_request),
            { 'Content-Type' => 'text/plain' },
            ['Invalid request path. Valid format: /service/z/x/y.ext']
          ]
        end

        path = Hash[match.names.map(&:to_sym).zip(match.captures)]
        @app.call(path)
      end
    end
  end
end
