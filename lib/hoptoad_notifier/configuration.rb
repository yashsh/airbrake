module HoptoadNotifier
  class Configuration

    # The API key for your project, found on the project edit form.
    attr_accessor :api_key

    # The host to connect to (defaults to hoptoadapp.com).
    attr_accessor :host

    # The port on which your Hoptoad server runs (defaults to 443 for secure
    # connections, 80 for insecure connections).
    attr_accessor :port

    # +true+ for https connections, +false+ for http connections.
    attr_accessor :secure

    # The HTTP open timeout in seconds (defaults to 2).
    attr_accessor :http_open_timeout

    # The HTTP read timeout in seconds (defaults to 5).
    attr_accessor :http_read_timeout

    # The hostname of your proxy server (if using a proxy)
    attr_accessor :proxy_host

    # The port of your proxy server (if using a proxy)
    attr_accessor :proxy_port

    # The username to use when logging into your proxy server (if using a proxy)
    attr_accessor :proxy_user

    # The password to use when logging into your proxy server (if using a proxy)
    attr_accessor :proxy_pass

    # A list of parameters that should be filtered out of what is sent to Hoptoad.
    # By default, all "password" attributes will have their contents replaced.
    attr_reader :params_filters

    # A list of environment keys that should be filtered out of what is send to Hoptoad.
    # Empty by default.
    attr_reader :environment_filters

    # A list of filters for cleaning and pruning the backtrace. See #filter_backtrace.
    attr_reader :backtrace_filters

    # A list of filters for ignoring exceptions. See #ignore_by_filter.
    attr_reader :ignore_by_filters

    DEFAULT_PARAMS_FILTERS = %w(password password_confirmation).freeze

    DEFAULT_BACKTRACE_FILTERS = [
      lambda { |line| line.gsub(/#{RAILS_ROOT}/, "[RAILS_ROOT]") },
      lambda { |line| line.gsub(/^\.\//, "") },
      lambda { |line|
        if defined?(Gem)
          Gem.path.inject(line) do |line, path|
            line.gsub(/#{path}/, "[GEM_ROOT]")
          end
        end
      },
      lambda { |line| line if line !~ %r{lib/hoptoad_notifier} }
    ].freeze

    alias_method :secure?, :secure

    def initialize
      @secure              = false
      @host                = 'hoptoadapp.com'
      @http_open_timeout   = 2
      @http_read_timeout   = 5
      @params_filters      = DEFAULT_PARAMS_FILTERS.dup
      @environment_filters = []
      @backtrace_filters   = DEFAULT_BACKTRACE_FILTERS.dup
      @ignore_by_filters   = []
    end

    # Takes a block and adds it to the list of backtrace filters. When the filters
    # run, the block will be handed each line of the backtrace and can modify
    # it as necessary. For example, by default a path matching the RAILS_ROOT
    # constant will be transformed into "[RAILS_ROOT]"
    def filter_backtrace(&block)
      self.backtrace_filters << block
    end

    # Takes a block and adds it to the list of ignore filters.  When the filters
    # run, the block will be handed the exception.  If the block yields a value
    # equivalent to "true," the exception will be ignored, otherwise it will be
    # processed by hoptoad.
    def ignore_by_filter(&block)
      self.ignore_by_filters << block
    end

    # Allows config options to be read like a hash
    def [](option)
      send(option)
    end

    def port #:nodoc:
      @port ||= if secure?
                  443
                else
                  80
                end
    end

    def protocol #:nodoc:
      if secure?
        'https'
      else
        'http'
      end
    end
  end
end