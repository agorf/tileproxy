# tileproxy

A minimal [slippy map tile][slippy] [Rack][]-based HTTP caching proxy and
demultiplexer.

[slippy]: http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
[Rack]: https://github.com/rack/rack

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

## Prerequisites

You need to have a recent version of [Ruby](https://www.ruby-lang.org/en/)
installed.

Once you have that, install [Bundler](http://bundler.io/) with `gem install
bundler`

## Installation

Clone the repository:

~~~ sh
$ git clone https://github.com/agorf/tileproxy.git
~~~

Enter the directory:

~~~ sh
$ cd tileproxy
~~~

Install the gems:

~~~ sh
$ bundle install
~~~

## Usage

Copy the sample services YAML file to `services.yaml`:

~~~ sh
$ cp services.yaml.sample services.yaml
~~~

Run the server on port 9292 (default):

~~~ sh
$ bundle exec rackup
~~~

Try it out by visiting <http://127.0.0.1:9292/openstreetmap/13/4252/2916.png> in
your web browser to get the tile of Chamonix, France from the [OpenStreetMap][]
service.

To use it with a mapping program like [GpsPrune][], simply set a new map
background with a first layer URL of <http://127.0.0.1:9292/openstreetmap/>

It is also possible to have the server listen on a custom port, e.g. 8080:

~~~ sh
$ bundle exec rackup -p 8080
~~~

To shut down the server, hit `Ctrl-C`.

**Warning:** Before using a map tile service with this program, please ensure
downloading and caching tiles does not violate its terms of use. Additionally,
virtually all map tile services require the display of a relevant copyright
and/or attribution notice which this program cannot satisfy as it is a proxy
server and not an end-user GUI.

[OpenStreetMap]: http://www.openstreetmap.org/

## Configuration

This program is configured through a `services.yaml` file that must be present
in the same directory as `config.ru`.

`services.yaml` is a YAML file which contains a mapping with service names as
keys and mappings as values. Service names may be composed of lowercase and
uppercase letters, numbers, underscore characters and nothing else.

Each service mapping value must contain a `url` key with a string value. The
following placeholders are supported:

* `%{z}` is replaced with the requested zoom (or precision)
* `%{x}` is replaced with the requested x tile
* `%{y}` is replaced with the requested y tile
* `%{quadkey}` is the [quadkey][]-encoded value of the zoom, x and y tile values

Any other placeholder not in the above list is replaced by key-value pairs that
must be present in the mapping value of the service. For example:

~~~ yaml
mymapservice:
  url: 'http://mymapservice.com/?z=%{z}&x=%{x}&y=%{y}.png?access_token=%{access_token}'
  access_token: 'myaccesstoken'
~~~

[quadkey]: https://msdn.microsoft.com/en-us/library/bb259689.aspx

## License

This project is licensed under the MIT license (see [LICENSE.txt][license]).

[license]: https://github.com/agorf/tileproxy/blob/master/LICENSE.txt

## Author

Angelos Orfanakos, <https://agorf.gr/>
