module Airbrake
  # Sends out the notice to Airbrake
  #modified yash 12/14/13 to send to Extinguisher app for SW 2013 
  #uses proto buf to post binary file to server
  class Sender

    #added yash - tells sender to use protobuf format - must be used in 
    #conjunction with send_to_airbrake_in_protobuf method
    attr_accessor :use_protobuf
    
    NOTICES_URI = '/notifier_api/v2/notices'.freeze
    HEADERS = {
      :xml => {
      'Content-type' => 'text/xml',
      'Accept'       => 'text/xml, application/xml'
    },:json => {
      'Content-Type' => 'application/json',
      'Accept'       => 'application/json'
    },
      :protobuf => 
      {
        'Content-Type' => 'application/octet-stream',
        'Accept'       => 'application/octet-stream, application/x-google-protobuf'
      }
    }
    
    PROTOBUF_URI = '/notification/'.freeze #added for posting binary data

    JSON_API_URI = '/api/v3/projects'.freeze
    HTTP_ERRORS = [Timeout::Error,
                   Errno::EINVAL,
                   Errno::ECONNRESET,
                   EOFError,
                   Net::HTTPBadResponse,
                   Net::HTTPHeaderSyntaxError,
                   Net::ProtocolError,
                   Errno::ECONNREFUSED,
                   OpenSSL::SSL::SSLError].freeze

    def initialize(options = {})
      [ :proxy_host,
        :proxy_port,
        :proxy_user,
        :proxy_pass,
        :protocol,
        :host,
        :port,
        :secure,
        :use_system_ssl_cert_chain,
        :http_open_timeout,
        :http_read_timeout,
        :project_id,
        :api_key
      ].each do |option|
        instance_variable_set("@#{option}", options[option])
      end
      
      @use_protobuf = false
    end


    # Sends the notice data off to Airbrake for processing.
    #
    # @param [Notice or String] notice The notice to be sent off
    #changed yash 12/14/13 - this is the original send_to_airbrake method now renamed
    def send_to_airbrake_in_xmljson(notice)
      data = prepare_notice(notice)
      http = setup_http_connection

      response = begin
                   http.post(url.respond_to?(:path) ? url.path : url,
                             data,
                             headers)
                 rescue *HTTP_ERRORS => e
                   log :level => :error,
                       :message => "Unable to contact the Airbrake server. HTTP Error=#{e}"
                   nil
                 end

      case response
      when Net::HTTPSuccess then
        log :level => :info,
            :message => "Success: #{response.class}",
            :response => response
      else
        log :level => :error,
            :message => "Failure: #{response.class}",
            :response => response,
            :notice => notice
      end

      if response && response.respond_to?(:body)
        error_id = response.body.match(%r{<id[^>]*>(.*?)</id>})
        error_id[1] if error_id
      end
    rescue => e
      log :level => :error,
        :message => "[Airbrake::Sender#send_to_airbrake] Cannot send notification. Error: #{e.class}" +
        " - #{e.message}\nBacktrace:\n#{e.backtrace.join("\n\t")}"

      nil
    end

    # Sends the notice data in binary format off to Extinguisher for processing.
    #
    # @param [Notice] notice The notice to be sent off in protobuf binary format
    #original method now changed to use protobuf format
    def send_to_airbrake(notice)
      @use_protobuf = true
      data = prepare_notice(notice)
      http = setup_http_connection
      
      response = begin
                   http.post(url.respond_to?(:path) ? url.path : url,
                             data,
                             headers)
                 rescue *HTTP_ERRORS => e
                   log :level => :error,
                       :message => "Unable to contact the Airbrake server. HTTP Error=#{e}"
                   nil
                 end

      case response
      when Net::HTTPSuccess then
        log :level => :info,
            :message => "Success: #{response.class}",
            :response => response
      else
        log :level => :error,
            :message => "Failure: #{response.class}",
            :response => response,
            :notice => notice
      end

      if response && response.respond_to?(:body)
        error_id = response.body.match(%r{<id[^>]*>(.*?)</id>})
        error_id[1] if error_id
      end
    rescue => e
      log :level => :error,
        :message => "[Airbrake::Sender#send_to_airbrake] Cannot send notification. Error: #{e.class}" +
        " - #{e.message}\nBacktrace:\n#{e.backtrace.join("\n\t")}"

      nil
    end

    attr_reader :proxy_host,
                :proxy_port,
                :proxy_user,
                :proxy_pass,
                :protocol,
                :host,
                :port,
                :secure,
                :use_system_ssl_cert_chain,
                :http_open_timeout,
                :http_read_timeout,
                :project_id,
                :api_key

    alias_method :secure?, :secure
    alias_method :use_system_ssl_cert_chain?, :use_system_ssl_cert_chain

  private
    # original prepare_notice function now being swaped -- Shayon 12/14/2013
    def prepare_notice(notice)
      if @use_protobuf
        notice.to_protobuf
      elsif json_api_enabled?
        begin
          JSON.parse(notice)
          notice
        rescue
          notice.to_json
        end
      else
        notice.respond_to?(:to_xml) ? notice.to_xml : notice
      end
    end
    
    

    def api_url
      if @use_protobuf
        return PROTOBUF_URI
      end
      if json_api_enabled?
        "#{JSON_API_URI}/#{project_id}/notices?key=#{api_key}"
      else
        NOTICES_URI
      end
    end

    def headers
      if @use_protobuf
        return HEADERS[:protobuf]
      end
      if json_api_enabled?
        HEADERS[:json]
      else
        HEADERS[:xml]
      end
    end

    def url
      URI.parse("#{protocol}://#{host}:#{port}").merge(api_url)
    end

    def log(opts = {})
      (opts[:logger] || logger).send(opts[:level], LOG_PREFIX + opts[:message])
      Airbrake.report_environment_info
      Airbrake.report_response_body(opts[:response].body) if opts[:response] && opts[:response].respond_to?(:body)
      Airbrake.report_notice(opts[:notice]) if opts[:notice]
    end

    def logger
      Airbrake.logger
    end

    def setup_http_connection
      http =
        Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_pass).
        new(url.host, url.port)

      http.read_timeout = http_read_timeout
      http.open_timeout = http_open_timeout

      if secure?
        http.use_ssl     = true

        http.ca_file      = Airbrake.configuration.ca_bundle_path
        http.verify_mode  = OpenSSL::SSL::VERIFY_PEER
      else
        http.use_ssl     = false
      end

      http
    rescue => e
      log :level => :error,
          :message => "[Airbrake::Sender#setup_http_connection] Failure initializing the HTTP connection.\n" +
                      "Error: #{e.class} - #{e.message}\nBacktrace:\n#{e.backtrace.join("\n\t")}"
      raise e
    end

    def json_api_enabled?
      !!(host =~ /collect.airbrake.io/) &&
        project_id =~ /\S/
    end
  end

  class CollectingSender < Sender
    # Used when test mode is enabled, to store the last XML notice locally

    attr_writer :last_notice_path

    def last_notice
      File.read last_notice_path
    end

    def last_notice_path
      File.expand_path(File.join("..", "..", "..", "resources", "notice.xml"), __FILE__)
    end

    #renamed original method - yash
    def send_to_airbrake_in_xmljson(notice)
      data = prepare_notice(notice)

      notices_file = File.open(last_notice_path, "w") do |file|
        file.puts data
      end

      super(notice)
    ensure
      notices_file.close if notices_file
    end

    #original method now changed to use protobuf method - yash
    def send_to_airbrake(notice)
      #data = prepare_notice(notice)
      data = notice

      notices_file = File.open(last_notice_path, "w") do |file|
        file.puts data
      end

      super(notice)
    ensure
      notices_file.close if notices_file
    end

  end
end
