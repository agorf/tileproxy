require 'test_helper'

require 'tileproxy/middleware/extension_validator'

class ExtensionValidatorTest < Minitest::Test
  def setup
    @app = MockApp.new
    subject = Tileproxy::Middleware::ExtensionValidator.new(@app)
    subject = Rack::Lint.new(subject)
    @req = Rack::MockRequest.new(subject)
  end

  def test_unknown_content_type
    @ext = '.foo'
    res = make_request

    assert_equal(400, res.status)
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Unknown Content-Type for requested file extension .foo',
      res.body
    )
  end

  def test_non_image_content_type
    @ext = '.mp3'
    res = make_request

    assert_equal(400, res.status)
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Non-image Content-Type audio/mpeg for requested file extension .mp3',
      res.body
    )
  end

  def test_image_content_type
    @ext = '.png'
    res = make_request

    assert_equal(200, res.status)
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal('image/png', @app.env['tileproxy.request_content_type'])
  end

  private def make_request
    opts = { 'tileproxy.path' => { ext: @ext } }
    res = @req.get("/openstreetmap/1/2/3#{@ext}", opts)
  end
end