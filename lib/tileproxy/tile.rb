module Tileproxy
  class Tile
    EARTH_RADIUS = 6378137 # meters
    ORIGIN_SHIFT = 2 * Math::PI * EARTH_RADIUS / 2.0

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

    def web_mercator_bbox
      left, top = lng_lat_to_meters(*left_top_lng_lat)
      right, bottom = lng_lat_to_meters(*right_bottom_lng_lat)
      [left, bottom, right, top]
    end
    alias_method :epsg3857_bbox, :web_mercator_bbox

    def wgs84_bbox
      left, bottom, right, top = web_mercator_bbox
      meters_to_lng_lat(left, bottom) + meters_to_lng_lat(right, top)
    end
    alias_method :epsg4326, :wgs84_bbox

    def params
      result = {
        x: x,
        y: y,
        z: z,
        quadkey: quadkey,
        bbox_web_mercator: bbox_param(web_mercator_bbox),
        bbox_wgs84: bbox_param(wgs84_bbox)
      }
      result[:bbox_epsg3857] = result[:bbox_web_mercator]
      result[:bbox_epsg4326] = result[:bbox_wgs84]
      result
    end

    private def bbox_param(bbox)
      sprintf('%.9f,%.9f,%.9f,%.9f', *bbox)
    end

    private def meters_to_lng_lat(mx, my)
      lng = (mx / ORIGIN_SHIFT) * 180
      lat = (my / ORIGIN_SHIFT) * 180
      lat = 180 / Math::PI * (2 * Math.atan(Math.exp(lat * Math::PI / 180.0)) - Math::PI / 2.0)
      [lng, lat]
    end

    private def lng_lat_to_meters(lng, lat)
      mx = lng * ORIGIN_SHIFT / 180.0
      my = Math.log(Math.tan((90 + lat) * Math::PI / 360.0)) / (Math::PI / 180.0)
      my *= ORIGIN_SHIFT / 180.0
      [mx, my]
    end

    protected def left_top_lng_lat
      n = 2**z
      lng_deg = x / n.to_f * 360.0 - 180
      lat_rad = Math.atan(Math.sinh(Math::PI * (1 - 2 * y / n.to_f)))
      lat_deg = (180.0 / Math::PI) * lat_rad
      [lng_deg, lat_deg]
    end

    private def right_bottom_lng_lat
      right_bottom.left_top_lng_lat
    end

    private def right_bottom
      Tile.new(x + 1, y + 1, z, extension: extension)
    end
  end
end
