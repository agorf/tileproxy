require 'test_helper'

require 'tileproxy/middleware/service_validator'

class ServiceValidatorTest < Minitest::Test
  def setup
    services = { 'openstreetmap' => {}, 'bing_aerial' => {} }.freeze

    @app = MockApp.new
    subject = Tileproxy::Middleware::ServiceValidator.new(@app, services: services)
    subject = Rack::Lint.new(subject)
    @req = Rack::MockRequest.new(subject)
  end

  def test_unavailable_service
    res = make_request('google_satellite')

    assert res.not_found?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Service "google_satellite" not found. Available services: bing_aerial, openstreetmap',
      res.body
    )
  end

  def test_available_service
    res = make_request('openstreetmap')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal('openstreetmap', @app.env['tileproxy.service_name'])
  end

  private def make_request(service)
    opts = { 'tileproxy.path' => { service: service } }
    res = @req.get("/#{service}/1/2/3.png", opts)
  end
end
