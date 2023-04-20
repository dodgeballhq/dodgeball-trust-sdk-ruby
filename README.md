# Dodgeball Ruby Server SDK

## What is Dodgeball?

DodgeBall is a no-code platform for Trust & Safety teams to orchestrate their security products and the human elements of their end-to-end anti-fraud operations.

This repository contains the assets for `dodgeball-trust-sdk-ruby`, a Ruby client for [Dodgeball](https://dodgeballhq.com/)

## Installation

Add gem from rubygems.org to Gemfile:

```ruby
gem 'dodgeball-trust-sdk-ruby'
```

Into environment gems from rubygems.org:

```ruby
gem install 'dodgeball-trust-sdk-ruby'
```

## Usage

Create an instance of the Client object:

```ruby
client = Dodgeball::Client.new({
  stub: true,
  write_key: 'write_key',
  dodgeball_api_url: 'https://localhost:3001',
  ssl: true,
  on_error: Proc.new { |status, msg| print msg }
})

```

Execute a no-code workflow to verify the event

```ruby
require 'dodgeball-trust-sdk-ruby'

riskyEvent = { type: 'PLACE_ORDER', data: { order: 'abc123' } }.freeze
options = { sync: true }
client.verify(riskyEvent, '<source id from the tracking client>', '<optional verfication id>', options)

```

## Documentation

For more information about how to use this SDK, please refer to our [documentation](https://app.dodgeballhq.com/developer)

## Testing

You can use the `stub` option to `Dodgeball::Client.new` to cause all requests to be stubbed, making it easier to test with this library.

## Contact Us

If you come across any issues while configuring or using Dodgeball, please feel free to [contact us](hello@dodgeballhq.com). We will be happy to help!

## Get Setup for Development and get a REPL

```bash
sudo gem update bundler
bundle install
rake console
```
