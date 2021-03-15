require 'test_helper'

require 'tileproxy/middleware/path_validator'

class PathValidatorTest < Minitest::Test
  def setup
    @app = MockApp.new
    subject = Tileproxy::Middleware::PathValidator.new(@app)
    subject = Rack::Lint.new(subject)
    @req = Rack::MockRequest.new(subject)
  end

  def test_root_path
    res = @req.get('/')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_missing_service
    res = @req.get('/1/2/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_invalid_service
    res = @req.get('/open+street+map/2/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_missing_z
    res = @req.get('/openstreetmap/2/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_invalid_z
    res = @req.get('/openstreetmap/z/2/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_too_big_z
    res = @req.get('/openstreetmap/19/2/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid zoom "19" in request path. Valid zoom: 0-18',
      res.body
    )
  end

  def test_missing_x
    res = @req.get('/openstreetmap/1/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_invalid_x
    res = @req.get('/openstreetmap/1/x/3.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_missing_y
    res = @req.get('/openstreetmap/1/2/.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_invalid_y
    res = @req.get('/openstreetmap/1/2/y.png')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_missing_extension
    res = @req.get('/openstreetmap/1/2/3')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_blank_extension
    res = @req.get('/openstreetmap/1/2/3.')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_invalid_extension
    res = @req.get('/openstreetmap/1/2/3.png_')

    assert res.bad_request?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal(
      'Invalid request path. Valid format: /service/z/x/y.ext',
      res.body
    )
  end

  def test_upper_case_extension
    res = @req.get('/openstreetmap/1/2/3.PNG')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'openstreetmap', z: '1', x: '2', y: '3', ext: '.PNG' },
      @app.env['tileproxy.path']
    )
  end

  def test_lower_case_extension
    res = @req.get('/openstreetmap/1/2/3.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'openstreetmap', z: '1', x: '2', y: '3', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end

  def test_mixed_case_extension
    res = @req.get('/openstreetmap/1/2/3.PnG')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'openstreetmap', z: '1', x: '2', y: '3', ext: '.PnG' },
      @app.env['tileproxy.path']
    )
  end

  def test_extension_with_numerical_digits
    res = @req.get('/openstreetmap/1/2/3.mp3')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'openstreetmap', z: '1', x: '2', y: '3', ext: '.mp3' },
      @app.env['tileproxy.path']
    )
  end

  def test_more_digits
    res = @req.get('/openstreetmap/12/2345/3456.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'openstreetmap', z: '12', x: '2345', y: '3456', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end

  def test_multiple_slashes
    res = @req.get('///openstreetmap//1//2//3.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'openstreetmap', z: '1', x: '2', y: '3', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end

  def test_underscored_service
    res = @req.get('/open_street_map/1/2/3.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'open_street_map', z: '1', x: '2', y: '3', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end

  def test_upper_case_service
    res = @req.get('/OPENSTREETMAP/1/2/3.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'OPENSTREETMAP', z: '1', x: '2', y: '3', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end

  def test_mixed_case_service
    res = @req.get('/OpenStreetMap/1/2/3.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: 'OpenStreetMap', z: '1', x: '2', y: '3', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end

  def test_service_with_numerical_digits
    res = @req.get('/0p3nst233tm4p/1/2/3.png')

    assert res.ok?
    assert_equal('text/plain', res.headers['Content-Type'])
    assert_equal('OK', res.body)
    assert_equal(
      { service: '0p3nst233tm4p', z: '1', x: '2', y: '3', ext: '.png' },
      @app.env['tileproxy.path']
    )
  end
end
