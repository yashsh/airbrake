require 'pp'
module Airbrake
  class Metrics

    cattr_accessor :request_counter, :duration_of_requests, :min_response_time, :max_response_time, :average_response_time, :all_requests

    def initialize(app)
      @app                    = app
      @@start_time            = Time.now
      @@all_requests          = []
      @@hash                  = {}
      @@duration_of_requests  = 0
      @exceptions             = Airbrake.configuration.exceptions
    end

    def call(env)

      # every hour send data to Airbrake
      if (Time.now - @@start_time) >= 3600
        Metrics.send_metrics
      end

      time = Time.now.getutc.strftime("%Y-%m-%d at %H:%M UTC")

      # clear hash params if new minute
      clear_hash_params unless @@hash.has_key?(time)

      @@all_requests << ::Rack::Request.new(env)

      begin
        status, headers, response = @app.call(env)

        if headers['X-Cascade'] == 'pass'
          Airbrake.configuration.exceptions << ActionController::RoutingError.new("No route matches [#{env["REQUEST_METHOD"]}] #{env["PATH_INFO"]}")
        end

      rescue Exception => ex
        raise ex
      ensure
        @exceptions = Airbrake.configuration.exceptions

        # TODO: track duration time separate for exceptions

        @@hash[time] = {"app_request_total_count" => @@all_requests.length,
                        "app_request_error_count" => @exceptions.length, 
                        "app_request_min_time"    => "#{@@min_response_time.to_i}[us]",
                        "app_request_avg_time"    => "#{@@average_response_time.to_f.round(3)}[us]",
                        "app_request_max_time"    => "#{@@max_response_time.to_i}[us]",
                        "app_request_total_time"  => "#{@@duration_of_requests.to_i}[us]"}
      end

      [status, headers.merge("Content-Type" => "text"), [body]]
      # [status, headers, response]

    end

    def body 
      body = "#{@@hash}"
    end

    def clear_hash_params
      @@all_requests                    = []
      Airbrake.configuration.exceptions = []
      @@duration_of_requests            = 0
      @@max_response_time               = nil
      @@min_response_time               = nil
      @@average_response_time           = nil
    end

    def self.send_metrics
      # TODO send hash to Airbrake
      @@hash = {} 
      @@start_time = Time.now
    end
  end
end
