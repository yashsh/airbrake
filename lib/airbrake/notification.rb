#!/usr/bin/env ruby
# Generated by the protocol buffer compiler. DO NOT EDIT!

require 'protocol_buffers'

module Airbrake
  # forward declarations
  class Notification < ::ProtocolBuffers::Message; end
  class Error < ::ProtocolBuffers::Message; end
  class ServerConfig < ::ProtocolBuffers::Message; end
  class Request < ::ProtocolBuffers::Message; end
  class Cookie < ::ProtocolBuffers::Message; end
  class CookieEntry < ::ProtocolBuffers::Message; end
  class RackData < ::ProtocolBuffers::Message; end
  class RailsData < ::ProtocolBuffers::Message; end
  class KeyValuePair < ::ProtocolBuffers::Message; end

  class Notification < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.Notification"

    required :string, :api_key, 1
    optional :int32, :version, 2
    required ::Airbrake::Error, :error, 3
    optional ::Airbrake::ServerConfig, :server_config, 4
    optional ::Airbrake::Request, :request, 5
  end

  class Error < ::ProtocolBuffers::Message
    # forward declarations
    class StackTrace < ::ProtocolBuffers::Message; end

    set_fully_qualified_name "Airbrake.Error"

    # nested messages
    class StackTrace < ::ProtocolBuffers::Message
      # forward declarations
      class Line < ::ProtocolBuffers::Message; end

      set_fully_qualified_name "Airbrake.Error.StackTrace"

      # nested messages
      class Line < ::ProtocolBuffers::Message
        set_fully_qualified_name "Airbrake.Error.StackTrace.Line"

        required :string, :file, 1
        required :string, :method, 2
        required :int32, :number, 3
      end

      repeated ::Airbrake::Error::StackTrace::Line, :lines, 1
    end

    required :string, :classname, 1
    required :string, :title, 2
    required ::Airbrake::Error::StackTrace, :stacktrace, 3
  end

  class ServerConfig < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.ServerConfig"

    optional :string, :hostname, 1
    optional :string, :ipaddress, 2
    optional :string, :language, 3
    optional :string, :framework, 4
    optional :string, :project_src_dir, 5
    optional :string, :environment, 6
  end

  class Request < ::ProtocolBuffers::Message
    # forward declarations

    # enums
    module RequestMethod
      include ::ProtocolBuffers::Enum

      set_fully_qualified_name "Airbrake.Request.RequestMethod"

      GET = 0
      POST = 1
      PUT = 2
      DELETE = 3
      PATCH = 4
      HEAD = 5
    end

    set_fully_qualified_name "Airbrake.Request"

    optional :string, :full_url, 1
    optional :string, :protocol, 2
    optional :string, :hostname, 3
    optional :int32, :port, 4
    optional :string, :path, 5
    optional :string, :query_string, 6
    optional ::Airbrake::Request::RequestMethod, :request_method, 7, :default => ::Airbrake::Request::RequestMethod::GET
    optional :int32, :content_length, 8
    optional :string, :mime_type, 9
    optional :bool, :sent_over_ssl, 10
    optional ::Airbrake::Cookie, :cookie, 11
    optional ::Airbrake::RackData, :rack_data, 12
    optional ::Airbrake::RailsData, :rails_data, 13
  end

  class Cookie < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.Cookie"

    repeated ::Airbrake::CookieEntry, :entries, 1
  end

  class CookieEntry < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.CookieEntry"

    required :string, :key, 1
    optional :string, :value, 2
    optional :string, :domain, 3
    optional :string, :path, 4
    optional :int64, :expire_after, 5
    optional :int32, :size, 6
    optional :bool, :http, 7
    optional :bool, :secure, 8
  end

  class RackData < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.RackData"

    repeated ::Airbrake::KeyValuePair, :parameters, 1
  end

  class RailsData < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.RailsData"

    optional :string, :controller_name, 1
    optional :string, :controller_action, 2
    repeated ::Airbrake::KeyValuePair, :parameters, 3
  end

  class KeyValuePair < ::ProtocolBuffers::Message
    set_fully_qualified_name "Airbrake.KeyValuePair"

    required :string, :key, 1
    optional :string, :value, 2
  end

end