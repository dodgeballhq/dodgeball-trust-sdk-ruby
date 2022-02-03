# frozen_string_literal: true

require 'logger'

module Dodgeball
  class Client
    # Wraps an existing logger and adds a prefix to all messages
    class PrefixedLogger
      def initialize(logger, prefix)
        @logger = logger
        @prefix = prefix
      end

      def debug(msg)
        @logger.debug("#{@prefix} #{msg}")
      end

      def info(msg)
        @logger.info("#{@prefix} #{msg}")
      end

      def warn(msg)
        @logger.warn("#{@prefix} #{msg}")
      end

      def error(msg)
        @logger.error("#{@prefix} #{msg}")
      end
    end

    module Logging
      class << self
        def logger
          return @logger if @logger

          base_logger = if defined?(Rails)
                          Rails.logger
                        else
                          logger = Logger.new STDOUT
                          logger.progname = 'Dodgeball::Client'
                          logger
                        end
          @logger = PrefixedLogger.new(base_logger, '[dodgeball-ruby]')
        end

        attr_writer :logger
      end

      def self.included(base)
        class << base
          def logger
            Logging.logger
          end
        end
      end

      def logger
        Logging.logger
      end
    end
  end
end
