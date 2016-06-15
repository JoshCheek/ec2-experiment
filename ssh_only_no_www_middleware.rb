class SshOnlyNoWwwMiddleware
  PERMANENT_REDIRECT = 301 # https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.3.2

  def initialize(app)
    @app = app
  end

  def call(env)
    return redirect(env) if insecure?(env) || www_subdomain?(env)
    @app.call(env)
  end

  private

  def insecure?(env)
    # Not sure this is actually the best way, I determined it experimentally
    # I think that ELB uses someting like apache, which sets this variable,
    # since I'm forwarding 443 to 3000, and the SSL cert is unaccessable,
    # making the server's protocol http, even though it's being sent over the wire as https
    'http' == env['HTTP_X_FORWARDED_PROTO']
  end

  def www_subdomain?(env)
    env['HTTP_HOST'].start_with?("www.")
  end

  def redirect(env)
    [ PERMANENT_REDIRECT,
      {'Content-Type' => 'text/html', 'Location' => redirect_url(env)},
      [],
    ]
  end

  def redirect_url(env)
    request      = Rack::Request.new(env)
    uri          = URI request.url
    uri.scheme   = 'https'
    uri.port     = nil # 443 adds it into the url, but the browser will got o 443 by default, and it would be strange for many users to see the port in the url
    uri.hostname = uri.hostname.sub(/^www\./, '')
    uri.to_s
  end
end

__END__
# Before settling on URI, I was messing w/ the env hash, here were some things I added
# It's mostly based off of reading through https://github.com/rack/rack/blob/8ebe20c80ffabc7cbf797999e74baeb3315673fa/lib/rack/request.rb
#
# PORT_HTTP                 = 80
# PORT_HTTPS                = 443
#     redirect_env = env.merge(
#       'HTTP_X_FORWARDED_SSL'    => 'on'
#       'HTTP_X_FORWARDED_SCHEME' => 'https'
#       'HTTP_X_FORWARDED_PORT'   => PORT_HTTP,
#       'HTTP_X_FORWARDED_PROTO'  => 'https'
#       'SERVER_PORT'             => PORT_HTTPS,
#     )
#     if env['HTTP_HOST']
#       redirect_env['HTTP_X_FORWARDED_HOST'] =
#         env['HTTP_HOST']
#           .sub(":#{PORT_HTTP}", ":#{PORT_HTTPS}")
#           .sub(/^www\./i, '')
#     maybe_replace! redirect_env, 'SERVER_NAME', /^www\./i, '' ''
#
#     Request.new(redirect_env).url
#   end


# --------------------------------------

# This is the code I ultimately used to figure out the redirect_url method
# URI docs: http://www.rubydoc.info/stdlib/uri

require 'uri'
require 'stringio'
require 'rack/test'

include Rack::Test::Methods

def app
  lambda { |*| [200, {'Content-Type' => 'text/html'}, []] }
end

env = {
  "SERVER_SOFTWARE"=>"thin 1.6.4 codename Gob Bluth",
  "SERVER_NAME"=>"www.joshcheek.com",
  "rack.input"=>StringIO.new,
  "rack.version"=>[1, 0],
  "rack.errors"=> $stderr,
  "rack.multithread"=>false,
  "rack.multiprocess"=>false,
  "rack.run_once"=>false,
  "REQUEST_METHOD"=>"GET",
  "REQUEST_PATH"=>"/abc",
  "PATH_INFO"=>"/",
  "REQUEST_URI"=>"/",
  "HTTP_VERSION"=>"HTTP/1.1",
  "HTTP_HOST"=>"www.joshcheek.com:9292",
  "HTTP_CONNECTION"=>"keep-alive",
  "HTTP_UPGRADE_INSECURE_REQUESTS"=>"1",
  "HTTP_USER_AGENT"=> "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36",
  "HTTP_ACCEPT"=> "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
  "HTTP_ACCEPT_ENCODING"=>"gzip, deflate, sdch",
  "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8",
  "GATEWAY_INTERFACE"=>"CGI/1.2",
  "SERVER_PORT"=>"9292",
  "QUERY_STRING"=>"",
  "SERVER_PROTOCOL"=>"HTTP/1.1",
  "rack.url_scheme"=>"http",
  "SCRIPT_NAME"=>"",
  "REMOTE_ADDR"=>"127.0.0.1",
  "sinatra.commonlogger"=>true,
  "rack.tempfiles"=>[],
  "rack.request.query_string"=>"",
  "rack.request.query_hash"=>{},
  "sinatra.route"=>"GET /",
  "rack.logger" => Rack::NullLogger.new(app),
}

request      = Rack::Request.new(env)
request.url # => "http://www.joshcheek.com:9292/"
uri          = URI request.url.sub(/:\d+/, '')
uri.to_s # => "http://www.joshcheek.com/"
uri.scheme   = 'https'
uri.port     = nil
uri.hostname = uri.hostname.sub(/^www\./, '') # => "joshcheek.com"
uri.to_s # => "https://joshcheek.com/"


(uri.methods - Object.new.methods).grep(/por/)
# => [:port, :port=, :default_port, :set_port]
