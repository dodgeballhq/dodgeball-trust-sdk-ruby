require 'trust-sdk-ruby'

# ruby -Ilib tests/test.rb

client = Dodgeball::Client.new({
  stub: true,  
  write_key: 'write_key',
  dodgeball_api_url: 'https://localhost:3001',
  ssl: true,
  on_error: Proc.new { |status, msg| print msg }
})

workflow = {
  type: 'PLACE_ORDER',
  data: {
      order: 'abc123'
  }
}.freeze

options = {
  sync: true
}.freeze

client.verify(
  workflow,
  '7fe92d98-56c1-4811-afcd-19ee59638de4',
  '835a4bde-aab1-490b-8941-a4ae84423bc7',
  options
)
