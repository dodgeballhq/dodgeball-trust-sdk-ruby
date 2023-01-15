# frozen_string_literal: true

# https://github.com/codecov/codecov-ruby#usage
# require 'simplecov'
# SimpleCov.start
# require 'codecov'
# SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'dodgeball/client'
require 'active_support/time'

# Setting timezone for ActiveSupport::TimeWithZone to UTC
Time.zone = 'UTC'

# stop the tests and analyse trace at the error test
RSpec.configure do |c|
  c.fail_fast = true
end

module Dodgeball
  class Client
    WRITE_KEY = 'testsecret'
    URI = 'http://localhost:3000'
    PATH = URI + '/v1/verify'

    # TODO: Correct the internals
    VERIFY_EVENT_DATA = {
      :type => 'LOGIN',
      :data => {
        :customer_email => 'test@test.com',
        :account_id => 'abc123'
      }
    }
    SOURCE_ID = '7fe92d98-56c1-4811-afcd-19ee59638de4'
    VERIFICATION_ID = '835a4bde-aab1-490b-8941-a4ae84423bc7'
  end
end

# A backoff policy that returns a fixed list of values
class FakeBackoffPolicy
  def initialize(interval_values)
    @interval_values = interval_values
  end

  def next_interval
    raise 'FakeBackoffPolicy has no values left' if @interval_values.empty?

    @interval_values.shift
  end
end
