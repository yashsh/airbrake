require 'pp'
module Airbrake
  class Metrics

    cattr_accessor :request_counter, :duration_of_requests, :min_response_time, :max_response_time, :avg

    def initialize(app)
      @app                    = app
      @all_requests           = []
      @hash                   = {}
      @@duration_of_requests  = 0
      @@request_counter       = 0
      @error_counter          = 0
    end

    def call(env)

      # TODO: every hour send hash to Airbrake

      time = Time.now.getutc.strftime("%Y-%m-%d at %H:%M UTC")

      # clear hash params if new minute
      clear_hash_params if !@hash.has_key?(time)

      @all_requests << ::Rack::Request.new(env)
      @exceptions = Airbrake.configuration.exceptions

      begin
        status, headers, response = @app.call(env)
      rescue Exception => ex
        @error_counter += 1
        raise ex
      ensure

        # TODO: track duration time separate for exceptions
        
        @hash[time] = { "app_request_total_count" => @@request_counter,
                        "app_request_error_count" => @error_counter, 
                        "app_request_min_time"    => "#{@@min_response_time.to_i}[us]",
                        "app_request_avg_time"    => "#{@@avg.to_i}[us]",
                        "app_request_max_time"    => "#{@@max_response_time.to_i}[us]",
                        "app_request_total_time"  => "#{@@duration_of_requests.to_i}[us]"}
        pp @hash
      end

      [status, headers.merge("Content-Type" => "text"), [body]]
      # [status, headers, response]
      
    end

    def body 
      body = "#{@hash}"
    end

    def clear_hash_params
      @error_counter          = 0
      @@request_counter       = 0
      @@duration_of_requests  = 0
      @@max_response_time     = nil
      @@min_response_time     = nil
      @@avg                   = nil
    end
  end
end
