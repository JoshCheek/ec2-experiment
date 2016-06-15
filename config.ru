require_relative 'app'
require_relative 'ssh_only_no_www_middleware'

use SshOnlyNoWwwMiddleware
run App
