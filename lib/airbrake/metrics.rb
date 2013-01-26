module Airbrake
  class Metrics

    cattr_accessor :request_counter, :duration_of_requests, :duration_of_requests_sq, :min_response_time, :max_response_time, :average_response_time, :count

    def initialize(app)
      @app                      = app
      @@start_time              = Time.now
      @@request_counter         = 0
      @@hash                    = {}
      @@duration_of_requests    = 0.0
      @@duration_of_requests_sq = 0.0
      @precision                = 60 #every minute
      @@count                   = 0
    end

    def call(env)

      # every hour send data to Airbrake
      if (Time.now.min - @@start_time.min) >= 60
        Metrics.send_metrics
        Metrics.reset!
      end

      time = (Time.now.to_i/@precision*@precision) * 1000

      # clear hash params if new minute
      clear_hash_params unless @@hash.has_key?(time)

      @@request_counter += 1

      begin
        status, headers, body = @app.call(env)

        if headers['X-Cascade'] == 'pass'
           exceptions << ActionController::RoutingError.new("No route matches [#{env["REQUEST_METHOD"]}] #{env["PATH_INFO"]}")
        end

      ensure

        @@hash[time] = {"duration"     => @precision * 1000,
                        "requestCount" => @@request_counter,
                        "errorCount"   => exceptions.length, 
                        "latencySum"   => @@duration_of_requests.round(3),
                        "latencySumsq" => @@duration_of_requests_sq.round(3),
                        "latencyMin"   => @@min_response_time.to_f.round(3),
                        "latencyAvg"   => @@average_response_time.to_f.round(3),
                        "latencyMax"   => @@max_response_time.to_f.round(3)}
      end

      [status, headers, body]

    end

    def exceptions
      Airbrake.configuration.exceptions
    end

    def clear_hash_params
      @@request_counter                 = 0
      Airbrake.configuration.exceptions = []
      @@duration_of_requests            = 0.0
      @@duration_of_requests_sq         = 0.0
      @@min_response_time               = nil
      @@average_response_time           = nil
      @@max_response_time               = nil
      @@count                           = 0
    end

    def self.reset!
      @@hash = {} 
      @@start_time = Time.now
    end

    def self.send_metrics
      Airbrake.sender.send_metrics(@@hash)
    end
  end
end
