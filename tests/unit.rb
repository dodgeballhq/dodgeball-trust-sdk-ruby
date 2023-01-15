# frozen_string_literal: true

require 'minitest/autorun'

class TestDodgeballClient < Minitest::Test
  def test_checkpoint
    client = Dodgeball::Client.new(:write_key => 'your_write_key')

    # Test case: Missing checkpoint_name
    assert_raises ArgumentError do
      client.checkpoint(nil, { :ip => '127.0.0.1' }, 'your_source_token', nil, 'your_session_id')
    end

    # Test case: Missing event
    assert_raises ArgumentError do
      client.checkpoint('checkpoint_name', nil, 'your_source_token', nil, 'your_session_id')
    end

    # Test case: Missing ip property on event
    assert_raises ArgumentError do
      client.checkpoint('checkpoint_name', { :other_property => 'value' }, 'your_source_token', nil, 'your_session_id')
    end

    # Test case: Missing session_id
    assert_raises ArgumentError do
      client.checkpoint('checkpoint_name', { :ip => '127.0.0.1' }, 'your_source_token', nil, nil)
    end

    # Test case: Successful request
    res = client.checkpoint('checkpoint_name', { :ip => '127.0.0.1' }, 'your_source_token', nil, 'your_session_id')
    assert_equal res.status, 200
  end

  def test_track
    client = Dodgeball::Client.new(:write_key => 'your_write_key')

    # Test case: Missing event
    assert_raises ArgumentError do
      client.track(nil, 'your_source_token', nil, 'your_session_id')
    end

    # Test case: Missing session_id
    assert_raises ArgumentError do
      client.track({ :ip => '127.0.0.1' }, 'your_source_token', nil, nil)
    end

    # Test case: Successful request
    res = client.track({ :ip => '127.0.0.1' }, 'your_source_token', nil, 'your_session_id')
    assert_equal res.status, 200
  end
end
