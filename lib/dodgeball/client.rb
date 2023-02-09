# frozen_string_literal: true

require 'time'
require 'uri'

require 'dodgeball/client/version'
require 'dodgeball/client/defaults'
require 'dodgeball/client/utils'
require 'dodgeball/client/request'
require 'dodgeball/client/response'
require 'dodgeball/client/logging'
require 'net/http'

module Dodgeball
  class Client
    include Dodgeball::Client::Utils
    include Dodgeball::Client::Logging

    # @param [Hash] opts
    # @option opts [String] :write_key Your project's write_key
    # @option opts [String] :dodgeball_api_url Your Dodgeball API URL
    # @option opts [Proc] :on_error Handles error calls from the API.
    # @option opts [Boolean] :ssl Whether to send the call via SSL
    # @option opts [Boolean] :stub Whether to cause all requests to be stubbed, making it easier to test
    def initialize(opts = {})
      symbolize_keys!(opts)
      Request.stub = opts[:stub] if opts.has_key?(:stub)

      @write_key = opts[:write_key]
      @dodgeball_api_url = opts[:dodgeball_api_url] || Defaults::Request::DODGEBALL_API_URL
      uri = URI(opts[:dodgeball_api_url])
      @host = uri.host
      @port = uri.port
      @on_error = opts[:on_error] || proc { |status, error| }
      @ssl = opts[:ssl].nil? ? Defaults::Request::SSL : opts[:ssl]

      check_write_key!
    end

    # Creates a checkpoint activity
    #
    # @param [Hash] attrs
    #
    # @option attrs [String] :checkpoint_name Name of the checkpoint to call (required)
    # @option attrs [Hash] :event The event to send to the checkpoint (required)
    # @option attrs [String] :source_token A Dodgeball generated token representing the device making the request
    # @option attrs [String] :user_id A unique identifier for the user making the request
    # @option attrs [String] :session_id The current session ID of the request (required)
    # @option attrs [String] :verification_id If a previous verification was performed on this request, pass it in here
    #
    # @return [Dodgeball::Client::Response]
    def checkpoint(checkpoint_name, event, source_token, user_id = nil, session_id = nil, verification_id = nil, options={ "options": { "sync": false, "timeout": 100, "webhook": "" } })
      raise ArgumentError, 'No checkpoint provided' unless checkpoint_name
      raise ArgumentError, 'No event provided' unless event
      raise ArgumentError, 'Event is missing required property: ip' unless event.has_key?(:ip)
      raise ArgumentError, 'No session provided' unless session_id

      request_headers = {}
      request_headers[Defaults::Request::SESSION_ID_HEADER] = session_id
      request_headers[Defaults::Request::VERIFICATION_ID_HEADER] = verification_id if verification_id
      request_headers[Defaults::Request::SOURCE_TOKEN_HEADER] = source_token if source_token
      request_headers[Defaults::Request::USER_ID_HEADER] = user_id if user_id
      event[:data] = {} unless event.key?(:data)
      body = { :event => { :type => checkpoint_name, **event, **options } }
      res = execute_request('checkpoint', body, request_headers)
      res
    end

    # Track an event
    #
    # @param [Hash] attrs
    #
    # @option attrs [Hash] :event The event to track (required)
    # @option attrs [String] :source_token A Dodgeball generated token representing the device making the request
    # @option attrs [String] :user_id A unique identifier for the user making the request
    # @option attrs [String] :session_id The current session ID of the request (required)
    #
    # @return [Dodgeball::Client::Response]
    def track(event, source_token, user_id = nil, session_id = nil, options={ "options": { "sync": false, "timeout": 100, "webhook": "" } })
      raise ArgumentError, 'No event provided' unless event
      raise ArgumentError, 'Event is missing required property: type' unless event.has_key?(:type)
      raise ArgumentError, 'No session provided' unless session_id
    
      request_headers = {}
      request_headers[Defaults::Request::SESSION_ID_HEADER] = session_id
      request_headers[Defaults::Request::SOURCE_TOKEN_HEADER] = source_token if source_token
      request_headers[Defaults::Request::USER_ID_HEADER] = user_id if user_id
      body = { **event, **options }
      res = execute_request('track', body, request_headers)
      res
    end
    
    private
    
    # private: Executes a request with common code to handle results.
    #
    def execute_request(request_function, body, request_specific_headers)
      path = generate_path(request_function)
      res = Request.new(:dodgeball_api_url => @dodgeball_api_url, :ssl => @ssl).post(@write_key, path, body, request_specific_headers)
      @on_error.call(res.status, res.response_body) unless res.status == 200
      res
    end

    # private: Adds the correct path root
    #
    # @param [String] Function name to build into a path
    def generate_path(request_function)
      Defaults::Request::PATH_ROOT + request_function
    end

    # private: Checks that the write_key is properly initialized
    def check_write_key!
      raise ArgumentError, 'Write key must be initialized' if @write_key.nil?
    end

    include Logging
  end
end
