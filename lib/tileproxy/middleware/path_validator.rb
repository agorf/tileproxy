require_relative 'base_middleware'

module Tileproxy
  module Middleware
    class PathValidator < BaseMiddleware
      # http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
      PATH_REGEX = %r{
        \A
        /+(?<service>\w+)
        /+(?<z>\d+)
        /+(?<x>\d+)
        /+(?<y>\d+)
        (?<ext>\.[A-Za-z0-9]+)
        \z
      }x.freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        match = env.fetch('PATH_INFO').match(PATH_REGEX)

        if match.nil?
          return http_error(
            :bad_request,
            'Invalid request path. Valid format: /service/z/x/y.ext'
          )
        end

        path = match.names.map(&:to_sym).zip(match.captures).to_h
        zoom = path[:z].to_i

        if zoom > 18
          return http_error(
            :bad_request,
            %(Invalid zoom "#{zoom}" in request path. Valid zoom: 0-18)
          )
        end

        env['tileproxy.path'] = path

        @app.call(env)
      end
    end
  end
end
