module Tileproxy
  class Service
    def initialize(config)
      @config = sample_values(symbolize_keys(config))
    end

    def tile_url(tile)
      sprintf(
        url.gsub(/%(?!{)/, '%%'), # Escape %
        url_args.merge(tile.params)
      )
    end

    private def url
      @config.fetch(:url)
    end

    private def url_args
      @config.dup.tap do |config|
        config.delete(:url)
      end
    end

    private def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end

    private def sample_values(hash)
      hash.transform_values do |value|
        if value.respond_to?(:sample)
          value.sample
        else
          value
        end
      end
    end
  end
end
