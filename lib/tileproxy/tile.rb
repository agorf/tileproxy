require_relative 'lng_lat'

module Tileproxy
  class Tile
    attr_reader :x, :y, :z, :extension

    def initialize(x, y, z, extension:)
      @x = x
      @y = y
      @z = z
      @extension = extension
    end

    def path
      File.join(z.to_s, x.to_s, [y, extension].join)
    end

    def quadkey
      z.downto(1).reduce([]) { |digits, i|
        digit = '0'.ord
        mask = 1 << i - 1
        digit += 1 if x & mask != 0
        digit += 2 if y & mask != 0
        digits << digit.chr
      }.join
    end

    def bbox_str
      sprintf('%.9f,%.9f,%.9f,%.9f', *spherical_mercator_bbox)
    end

    def params
      {
        x: x,
        y: y,
        z: z,
        bbox: bbox_str,
        quadkey: quadkey
      }
    end

    private def spherical_mercator_bbox
      left, top = left_top_lng_lat.spherical_mercator
      right, bottom = right_bottom_lng_lat.spherical_mercator
      [left, bottom, right, top]
    end

    protected def left_top_lng_lat
      n = 2**z
      lng_deg = x / n.to_f * 360.0 - 180
      lat_rad = Math.atan(Math.sinh(Math::PI * (1 - 2 * y / n.to_f)))
      lat_deg = (180.0 / Math::PI) * lat_rad
      LngLat.new(lng_deg, lat_deg)
    end

    private def right_bottom_lng_lat
      right_bottom.left_top_lng_lat
    end

    private def right_bottom
      Tile.new(x + 1, y + 1, z, extension: extension)
    end
  end
end
