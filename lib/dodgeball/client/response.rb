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

      def is_running
        return false unless @response_body[:success]

        case @response_body[:verification][:status]
        when 'PENDING', 'BLOCKED'
          true
        else
          false
        end
      end

      def is_allowed
        @response_body[:success] &&
          @response_body[:verification][:status] == 'COMPLETE' &&
          @response_body[:verification][:outcome] == 'APPROVED'
      end

      def is_denied
        return false unless @response_body[:success]

        @response_body[:verification][:outcome] == 'DENIED'
      end

      def is_undecided
        @response_body[:success] &&
          @response_body[:verification][:status] == 'COMPLETE' &&
          @response_body[:verification][:outcome] == 'PENDING'
      end

      def has_error
        !@response_body[:success] &&
          (@response_body[:verification][:status] == 'FAILED' &&
           @response_body[:verification][:outcome] == 'ERROR') ||
          (@response_body[:errors] && !@response_body[:errors].empty?)
      end

      def is_timeout
        !@response_body[:success] && @response_body[:isTimeout]
      end
    end
  end
end
