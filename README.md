# tileproxy

A minimal [slippy map tile][slippy] HTTP caching proxy and demultiplexer.

[slippy]: http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames

## Rationale

Some mapping progreams (e.g. [GpsPrune][]) let you define and use custom map
tile services, expecting the service to accept HTTP requests in the [slippy map
tile name][slippy] format e.g. `/13/4252/2916.png`, where `13` is the zoom,
`4252` the x tile, and `2916` the y tile.

Suppose a map tile service you want to use responds to parameterized HTTP
requests like `?z=13&x=4252&y=2916`.

How do you bridge the two?

This program does exactly that by sitting in the middle and translating the
slippy map tile name to a request path that each map tile service can
understand.

Additionally, it caches downloaded tiles so that they can be served from the
filesystem in subsequent requests.

Finally, it is also a demultiplexer as it can run once and dispatch HTTP
requests to different map tile services based on the first component of the
request path.

[GpsPrune]: https://activityworkshop.net/software/gpsprune/

## Configuration

This program is configured with a `services.yml` file that must be present in
the same directory as `config.ru` by default. It's possible to change the path
to the configuration file with the `CONFIG_PATH` environment variable.

`services.yml` is a [YAML][] file which maps service names to their
configurations.

Service names may contain lowercase and uppercase letters, numbers and
underscore characters.

Service configurations must contain a `url` with the following supported
placeholders:

* `%{z}` is replaced with the requested zoom (precision)
* `%{x}` is replaced with the x value (column) of the requested tile
* `%{y}` is replaced with the y value (row) of the requested tile
* `%{quadkey}` is replaced with the [quadkey][] of the requested zoom, x and
  y values
* `%{bbox_web_mercator}` or `%{bbox_epsg3857}` is replaced with the
  [Web Mercator][mercator] (EPSG:3857) bounding box of the requested zoom, x and
  y values
* `%{bbox_wgs84}` or `%{bbox_epsg4326}` is replaced with the [WGS 84][wgs84]
  (EPSG:4326) bounding box of the requested zoom, x and y values

Any other placeholder is replaced by key-value pairs that must be present in the
mapping value of the service. For example:

~~~ yaml
mymapservice:
  url: 'https://mymapservice.com/?z=%{z}&x=%{x}&y=%{y}.png?access_token=%{access_token}'
  access_token: 'myaccesstoken'
~~~

It is also possible to distribute requests among many servers by using an array
of values. For example:

~~~ yaml
openstreetmap:
  url: 'https://%{server}.tile.openstreetmap.org/%{z}/%{x}/%{y}.png'
  server:
    - a
    - b
    - c
~~~

To start off, copy the sample services YAML file to `services.yml` and customize
it:

~~~ sh
$ cp services.yml.sample services.yml
~~~

[YAML]: https://en.wikipedia.org/wiki/YAML
[wgs84]: https://en.wikipedia.org/wiki/World_Geodetic_System
[mercator]: https://en.wikipedia.org/wiki/Web_Mercator_projection
[quadkey]: https://msdn.microsoft.com/en-us/library/bb259689.aspx

## Installation

Clone the repository:

~~~ sh
$ git clone https://github.com/agorf/tileproxy.git
$ cd tileproxy
~~~

With [Docker][], you don't need Ruby, Bundler, Gems etc. Just build the image:

    $ docker-compose build tileproxy

If you don't have Docker, install the necessary Gems with [Bundler][]:

    $ bundle install

[Docker]: https://www.docker.com/
[Bundler]: https://bundler.io/

## Usage

Run the server on port 9292 (default) with [Docker][]:

~~~ sh
docker-compose up tileproxy
~~~

Without Docker:

~~~ sh
$ bundle exec rackup
~~~

Try it out by visiting <http://127.0.0.1:9292/openstreetmap/13/4252/2916.png> in
your web browser to get the tile of Chamonix, France from [OpenStreetMap][].

To use it with [GpsPrune][], simply set a new map background with a first layer
URL of <http://127.0.0.1:9292/openstreetmap/>

It is also possible to have the server listen on a custom port with the `-p`
option, e.g. `-p 8000`

To shut down the server, hit `Ctrl-C`

To clear the cache, remove the path `~/.cache/tileproxy`

## Disclaimer

Before using a map tile service with this program, please ensure downloading and
caching tiles does not violate the service's terms of use. Know that virtually
all map tile services require the display of a relevant copyright and/or
attribution notice which this program does not satisfy as it is a proxy server
and not an end-user GUI.

[OpenStreetMap]: https://www.openstreetmap.org/

## License

[MIT](https://github.com/agorf/tileproxy/blob/master/LICENSE.txt)

## Author

[Angelos Orfanakos](https://angelos.dev/)
