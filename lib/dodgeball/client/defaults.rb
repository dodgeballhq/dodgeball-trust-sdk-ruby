# frozen_string_literal: true

module Dodgeball
  class Client
    module Defaults
      module Request
        # HOST/PORT Used for testing
        HOST = 'localhost'.freeze
        PORT = 3000.freeze
        PATH_ROOT = '/v1/'.freeze
        DODGEBALL_API_URL = 'http://localhost:3000'.freeze
        
        DEFAULT_READ_TIMEOUT = 8.freeze
        DEFAULT_OPEN_TIMEOUT = 4.freeze
        SSL = true.freeze
        HEADERS = { 'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'User-Agent' => "dodgeball-ruby/#{Client::VERSION}" }.freeze
        RETRIES = 10.freeze

        SECRET_KEY_HEADER = 'Dodgeball-Secret-Key'.freeze
        SESSION_ID_HEADER = 'Dodgeball-Session-Id'.freeze
        SOURCE_ID_HEADER = 'Dodgeball-Source-Id'.freeze
        SOURCE_TOKEN_HEADER = 'Dodgeball-Source-Token'.freeze
        VERIFICATION_ID_HEADER = 'Dodgeball-Verification-Id'.freeze
        CUSTOM_SOURCE_ID_HEADER = 'Dodgeball-Custom-Source-Id'.freeze
        CUSTOMER_ID_HEADER = 'Dodgeball-Customer-Id'.freeze
      end

      module BackoffPolicy
        MIN_TIMEOUT_MS = 100.freeze
        MAX_TIMEOUT_MS = 10000.freeze
        MULTIPLIER = 1.5.freeze
        RANDOMIZATION_FACTOR = 0.5.freeze
      end
    end
  end
end
