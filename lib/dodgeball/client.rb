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

    # Verifies an event and executes a workflow
    #
    # @param [Hash] attrs
    #
    # @option attrs [Hash] :workflow Any input to pass to the workflow (required)
    # @option attrs [String] :dodgeball_id ID of the user from the client (required)
    # @option attrs [String] :verification_id if there was a previous verification executed in the client (optional)
    # @option attrs [Hash] :options Options to pass to the workflow (optional)
    def verify(workflow, dodgeball_id, verification_id=nil, options=nil)
      raise ArgumentError.new('No workflow provided') unless workflow
      raise ArgumentError.new('No dodgeball_id provided') unless dodgeball_id
      request_headers={}
      request_headers[Defaults::Request::VERIFICATION_ID_HEADER] = verification_id if verification_id
      request_headers[Defaults::Request::SOURCE_ID_HEADER] = dodgeball_id
      body = {event: workflow, options: options}
      res=execute_request('verify', body, request_headers)
      res
    end


    private

    # private: Executes a request with common code to handle results.
    #
    def execute_request(request_function, body, request_specific_headers)
      path=generate_path(request_function)
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
