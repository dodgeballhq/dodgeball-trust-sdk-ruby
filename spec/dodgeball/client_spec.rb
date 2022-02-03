# frozen_string_literal: true

require 'spec_helper'

module Dodgeball
  class Client
    describe Client do
      let(:client) { Dodgeball::Client.new(write_key: WRITE_KEY, dodgeball_api_url: URI, stub: true) }

      describe '#verify' do
        it 'errors without an event' do
          expect { client.verify(nil, SOURCE_ID, VERIFICATION_ID) }.to raise_error(ArgumentError)
        end

        it 'errors without source id' do
          expect { client.verify(VERIFY_EVENT_DATA,nil,VERIFICATION_ID) }.to raise_error(ArgumentError)
        end

        it 'does not error with only the required options' do
          expect do
            client.verify(VERIFY_EVENT_DATA,SOURCE_ID)
          end.to_not raise_error
        end

        it 'does not error when given string keys' do
          expect { client.verify(Utils.stringify_keys(VERIFY_EVENT_DATA),SOURCE_ID)}.to_not raise_error
        end
      end

      describe '#initialize' do
        it 'errors if no write_key is supplied' do
          expect { Client.new }.to raise_error(ArgumentError)
        end

        it 'does not error if a write_key is supplied' do
          expect do
            Client.new :write_key => WRITE_KEY, :dodgeball_api_url => URI
          end.to_not raise_error
        end

        it 'does not error if a write_key is supplied as a string' do
          expect do
            Client.new 'write_key' => WRITE_KEY, :dodgeball_api_url => URI
          end.to_not raise_error
        end
      end
    end
  end
end
