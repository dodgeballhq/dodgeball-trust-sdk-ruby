# frozen_string_literal: true

module Dodgeball
  class Client
    class Response
      attr_reader :status, :response_body

      # public: Simple class to wrap responses from the API
      #
      #
      def initialize(status = 200, response_body = nil)
        @status = status
        @response_body = response_body
      end
    end
  end
end
