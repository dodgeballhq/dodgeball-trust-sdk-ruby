# frozen_string_literal: true

module Dodgeball
  class Client
    module Defaults
      module Request
        # HOST/PORT Used for testing
        HOST = 'localhost'
        PORT = 3000
        PATH_ROOT = '/v1/'
        DODGEBALL_API_URL = 'http://localhost:3000'

        DEFAULT_READ_TIMEOUT = 8
        DEFAULT_OPEN_TIMEOUT = 4
        SSL = true
        HEADERS = { 'Accept' => 'application/json',
                    'Content-Type' => 'application/json',
                    'User-Agent' => "dodgeball-ruby/#{Client::VERSION}" }.freeze
        RETRIES = 10

        SECRET_KEY_HEADER = 'Dodgeball-Secret-Key'
        SESSION_ID_HEADER = 'Dodgeball-Session-Id'
        SOURCE_ID_HEADER = 'Dodgeball-Source-Id'
        SOURCE_TOKEN_HEADER = 'Dodgeball-Source-Token'
        VERIFICATION_ID_HEADER = 'Dodgeball-Verification-Id'
        CUSTOM_SOURCE_ID_HEADER = 'Dodgeball-Custom-Source-Id'
        CUSTOMER_ID_HEADER = 'Dodgeball-Customer-Id'
      end

      module BackoffPolicy
        MIN_TIMEOUT_MS = 100
        MAX_TIMEOUT_MS = 10000
        MULTIPLIER = 1.5
        RANDOMIZATION_FACTOR = 0.5
      end
    end
  end
end
