module Tileproxy
  EQUATORIAL_RADIUS = 6378137 # meters (WGS 84)

  LngLat = Struct.new(:lng, :lat) do
    def spherical_mercator
      lng_rad = lng * (Math::PI / 180.0)
      lat_rad = lat * (Math::PI / 180.0)
      x = EQUATORIAL_RADIUS * lng_rad
      y = EQUATORIAL_RADIUS * Math.log(Math.tan((Math::PI * 0.25) + (0.5 * lat_rad)))
      [y, x]
    end
  end
end
