# frozen_string_literal: true

require_relative '../lib/dodgeball/client'
require 'minitest/autorun'

class TestDodgeballClient < Minitest::Test
  def test_checkpoint
    client = Dodgeball::Client.new({
      stub: false,  
      write_key: 'SECRET_KEY',
      dodgeball_api_url: 'https://api.dev.dodgeballhq.com/',
      ssl: true,
      on_error: Proc.new { |status, msg| print msg }
    })

    # Test case: Missing checkpoint_name
    assert_raises ArgumentError do
      client.checkpoint(nil, { :ip => '127.0.0.1' }, 'SOURCE_TOKEN', nil, 'SESSION_ID')
    end

    # Test case: Missing event
    assert_raises ArgumentError do
      client.checkpoint('checkpoint_name', nil, 'SOURCE_TOKEN', nil, 'SESSION_ID')
    end

    # Test case: Missing ip property on event
    assert_raises ArgumentError do
      client.checkpoint('checkpoint_name', { :other_property => 'value' }, 'SOURCE_TOKEN', nil, 'SESSION_ID')
    end

    # Test case: Missing session_id
    assert_raises ArgumentError do
      client.checkpoint('checkpoint_name', { :ip => '127.0.0.1' }, 'SOURCE_TOKEN', nil, nil)
    end

    # Test case: Successful request
    res = client.checkpoint('checkpoint_name', { :ip => '127.0.0.1' }, nil, nil, 'SESSION_ID')
    assert_includes [200, 201], res.status
    assert_equal true, JSON.parse(res.response_body)["success"]
  end

  def test_track
    client = Dodgeball::Client.new({
      stub: false,  
      write_key: 'SECRET_KEY',
      dodgeball_api_url: 'https://api.dev.dodgeballhq.com/',
      ssl: true,
      on_error: Proc.new { |status, msg| print msg }
    })

    # Test case: Missing event
    assert_raises ArgumentError do
      client.track(nil, 'SOURCE_TOKEN', nil, 'SESSION_ID')
    end

    # Test case: Missing event.type
    assert_raises ArgumentError do
      client.track({ :ip => '127.0.0.1' }, 'SOURCE_TOKEN', nil, nil)
    end

    # Test case: Missing session_id
    assert_raises ArgumentError do
      client.track({ :ip => '127.0.0.1' }, 'SOURCE_TOKEN', nil, nil)
    end

    # Test case: Successful request
    res = client.track({ :ip => '127.0.0.1', :type => 'TYPE' }, 'SOURCE_TOKEN', nil, 'SESSION_ID')
    assert_includes [200, 201], res.status
    assert_equal true, JSON.parse(res.response_body)["success"]
  end
end
