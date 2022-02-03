# frozen_string_literal: true

require 'spec_helper'

module Dodgeball
  class Client
    describe Response do
      describe '#status' do
        it { expect(subject).to respond_to(:status) }
      end

      describe '#response_body' do
        it { expect(subject).to respond_to(:response_body) }
      end

      describe '#initialize' do
        let(:status) { 404 }
        let(:response_body) { '{"key" : "value" }' }

        subject { described_class.new(status, response_body) }

        it 'sets the instance variable status' do
          expect(subject.instance_variable_get(:@status)).to eq(status)
        end

        it 'sets the instance variable response_body' do
          expect(subject.instance_variable_get(:@response_body)).to eq(response_body)
        end
      end
    end
  end
end
