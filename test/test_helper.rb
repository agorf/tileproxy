require 'minitest/autorun'
require 'rack'

class Minitest::Test
  class MockApp
    attr_reader :env

    def call(env)
      @env = env
      [200, { 'Content-Type' => 'text/plain' }, ['OK']]
    end
  end
end
