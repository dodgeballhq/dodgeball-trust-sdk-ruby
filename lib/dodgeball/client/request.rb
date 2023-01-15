# frozen_string_literal: true

require 'dodgeball/client/defaults'
require 'dodgeball/client/utils'
require 'dodgeball/client/response'
require 'dodgeball/client/logging'
require 'dodgeball/client/backoff_policy'
require 'net/http'
require 'net/https'
require 'json'
require 'pry'
require 'uri'

module Dodgeball
  class Client
    class Request
      include Dodgeball::Client::Defaults::Request
      include Dodgeball::Client::Utils
      include Dodgeball::Client::Logging

      # public: Creates a new request object to send dodgeball api request
      #
      def initialize(options = {})
        options[:host] ||= HOST
        options[:port] ||= PORT

        options[:ssl] = options[:ssl].nil? ? SSL : options[:ssl]

        @headers = options[:headers] || HEADERS
        @retries = options[:retries] || RETRIES
        @backoff_policy =
          options[:backoff_policy] || Dodgeball::Client::BackoffPolicy.new

        uri = URI(options[:dodgeball_api_url] || DODGEBALL_API_URL)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = options[:ssl]
        http.read_timeout = DEFAULT_READ_TIMEOUT
        http.open_timeout = DEFAULT_OPEN_TIMEOUT

        @http = http
      end

      # public: Posts the write key and path to the API.
      #
      # returns - Response of the status and error if it exists
      def post(write_key, path, request_body, request_specific_headers = nil)
        last_response, exception = retry_with_backoff(@retries) do
          status_code, response_body = send_request(write_key, path, request_body, request_specific_headers)
          should_retry = should_retry_request?(status_code, response_body)
          logger.debug("Response status code: #{status_code}")
          logger.debug("Response response body: #{response_body}") if response_body

          [Response.new(status_code, response_body), should_retry]
        end

        if exception
          logger.error(exception.message)
          puts "E #{exception.message}"
          exception.backtrace.each { |line| logger.error(line) }
          Response.new(-1, exception.to_s)
        else
          last_response
        end
      end

      private

      def should_retry_request?(status_code, body)
        if status_code >= 500
          true # Server error
        elsif status_code == 429
          true # Rate limited
        elsif status_code >= 400
          logger.error(body)
          false # Client error. Do not retry, but log
        else
          false
        end
      end

      # Takes a block that returns [result, should_retry].
      #
      # Retries upto `retries_remaining` times, if `should_retry` is false or
      # an exception is raised. `@backoff_policy` is used to determine the
      # duration to sleep between attempts
      #
      # Returns [last_result, raised_exception]
      def retry_with_backoff(retries_remaining, &block)
        result, caught_exception = nil
        should_retry = false

        begin
          result, should_retry = yield
          return [result, nil] unless should_retry
        rescue StandardError => e
          should_retry = true
          caught_exception = e
        end

        if should_retry && (retries_remaining > 1)
          logger.debug("Retrying request, #{retries_remaining} retries left")
          sleep(@backoff_policy.next_interval.to_f / 1000)
          retry_with_backoff(retries_remaining - 1, &block)
        else
          [result, caught_exception]
        end
      end

      # Sends a request to the path, returns [status_code, body]
      def send_request(write_key, path, body, request_specific_headers)
        payload = JSON.generate(body) if body

        request_headers = (@headers || {}).merge(request_specific_headers || {})
        request_headers[SECRET_KEY_HEADER] = write_key
        request = Net::HTTP::Post.new(path, request_headers)

        if self.class.stub
          logger.debug "stubbed request to #{path}: " \
            "write key = #{write_key}, payload = #{payload}"

          [200, '{}']
        else
          puts payload
          response = @http.request(request, payload)
          [response.code.to_i, response.body]
        end
      end

      class << self
        attr_writer :stub

        def stub
          @stub || ENV['STUB']
        end
      end
    end
  end
end
