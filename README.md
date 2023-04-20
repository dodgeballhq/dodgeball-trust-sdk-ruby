# Dodgeball Server Trust SDK for Ruby

## Purpose

[Dodgeball](https://dodgeballhq.com) enables developers to decouple security logic from their application code. This has several benefits including:

- The ability to toggle and compare security services like fraud engines, MFA, KYC, and bot prevention.
- Faster responses to new attacks. When threats evolve and new vulnerabilities are identified, your application's security logic can be updated without changing a single line of code.
- The ability to put in placeholders for future security improvements while focussing on product development.
- A way to visualize all application security logic in one place.

The Dodgeball Server Trust SDK for Ruby makes integration with the Dodgeball API easy and is maintained by the Dodgeball team.

## Prerequisites

You will need to obtain an API key for your application from the [Dodgeball developer center](https://app.dodgeballhq.com/developer).

## Related

Check out the [Dodgeball Trust Client SDK](https://npmjs.com/package/@dodgeball/trust-sdk-client) for how to integrate Dodgeball into your frontend applications.

## Installation

```ruby
gem install 'dodgeball-trust-sdk-ruby'
```

## Usage

Create an instance of the Client object:

```ruby
db_client = Dodgeball::Client.new({write_key: 'WRITE_KEY'})
client = Dodgeball::Client.new({
  stub: true,
  write_key: 'write_key',
  dodgeball_api_url: 'https://localhost:3001',
  ssl: true,
  on_error: Proc.new { |status, msg| print msg }
})
```

```ruby
require 'dodgeball-trust-sdk-ruby'

# Here's a simple utility method for grabbing the originating IP address from the request.
def get_ip(request)
  forwarded_for = request.env['HTTP_X_FORWARDED_FOR']
  forwarded_for&.split(',')&.first || request.ip
end

post '/api/orders' do
  # In moments of risk, call a checkpoint within Dodgeball to verify the request is allowed to proceed
  checkpoint_response = dodgeball.checkpoint(
    checkpoint_name: 'PLACE_ORDER',
    event: {
      ip: get_ip(request),
      data: {
        order: request.body.order
      }
    },
    source_token: request.env['X-DODGEBALL-SOURCE-TOKEN'], # Obtained from the Dodgeball Client SDK, represents the device making the request
    session_id: session[:id],
    customer_id: session[:customer_id],
    verification_id: request.env['X-DODGEBALL-VERIFICATION-ID']
  )

  if dodgeball.is_allowed?(checkpoint_response)
    # Proceed with placing the order
    placed_order = database.create_order(request.body.order)
    status 200
    { order: placed_order }.to_json
  elsif dodgeball.is_running?(checkpoint_response)
    # If the outcome is pending, send the verification to the frontend to do additional checks (such as MFA, KYC)
    status 202
    { verification: checkpoint_response.verification }.to_json
  elsif dodgeball.is_denied?(checkpoint_response)
    # If the request is denied, you can return the verification to the frontend to display a reason message
    status 403
    { verification: checkpoint_response.verification }.to_json
  else
    # If the checkpoint failed, decide how you would like to proceed. You can return the error, choose to proceed, retry, or reject the request.
    status 500
    { message: checkpoint_response.errors }.to_json
  end
end

# Start the server
set :port, ENV['APP_PORT']
run!
```

## API

### Configuration

---

The package requires a secret API key in the constructor.

```ruby
db_client = Dodgeball::Client.new({write_key: 'WRITE_KEY'})
```

Optionally, you can pass in several configuration options to the constructor:

```ruby
client = Dodgeball::Client.new({
  stub: true,
  write_key: 'write_key',
  dodgeball_api_url: 'https://localhost:3001',
  ssl: true,
  on_error: Proc.new { |status, msg| print msg }
})
```

### Call a Checkpoint

---

Checkpoints represent key moments of risk in an application and at the core of how Dodgeball works. A checkpoint can represent any activity deemed to be a risk. Some common examples include: login, placing an order, redeeming a coupon, posting a review, changing bank account information, making a donation, transferring funds, creating a listing.

### Parameters

| Parameter         | Required | Description                                                                                                                                                                    |
| :---------------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `checkpoint_name` | `true`   | The name of the checkpoint to call.                                                                                                                                            |
| `event`           | `true`   | The event to send to the checkpoint.                                                                                                                                           |
| `event[:ip]`      | `true`   | The IP address of the device where the request originated.                                                                                                                     |
| `event[:data]`    | `false`  | A hash containing arbitrary data to send in to the checkpoint.                                                                                                                 |
| `source_token`    | `false`  | A Dodgeball generated token representing the device making the request. Obtained from the [Dodgeball Trust Client SDK](https://npmjs.com/package/@dodgeball/trust-sdk-client). |
| `session_id`      | `true`   | The current session ID of the request.                                                                                                                                         |
| `customer_id`         | `false`  | When you know the ID representing the user making the request in your database (ie after registration), pass it in here. Otherwise, leave it as `nil`.                         |
| `verification_id` | `false`  | If a previous verification was performed on this request, pass it in here. See the [useVerification](#useverification) section below for more details.                         |

### Example

````ruby
checkpoint_response = dodgeball.checkpoint(
  checkpoint_name: "CHECKPOINT_NAME",
  event: {
    ip: "127.0.0.1", # The IP address of the device where the request originated
    data: {
      # Arbitrary data to send in to the checkpoint...
      transaction: {
        amount: 100,
        currency: 'USD',
      },
      payment_method: {
        token: 'ghi789'
      }
    }
  },
  source_token: "abc123...", # Obtained from the Dodgeball Client SDK, represents the device making the request
  session_id: "session_def456", # The current session ID of the request
  customer_id: "user_12345", # When you know the ID representing the user making the request in your database (ie after registration), pass it in here. Otherwise leave it as nil.
  verification_id: "def456" # Optional, if you have a verification ID, you can pass it in here
)

### Interpreting the Checkpoint Response
___
Calling a checkpoint creates a verification in Dodgeball. The status and outcome of a verification determine how your application should proceed. Continue to [possible checkpoint responses](#possible-checkpoint-responses) for a full explanation of the possible status and outcome combinations and how to interpret them.
```ruby
checkpoint_response = {
  success: boolean,
  errors: [
    {
      code: number,
      message: string
    }
  ],
  version: string,
  verification: {
    id: string,
    status: string,
    outcome: string
  }
}
````

| Property               | Description                                                                                                                       |
| :--------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| `success`              | Whether the request encountered any errors was successful or failed.                                                              |
| `errors`               | If the `success` flag is `false`, this will contain an array of error objects each with a `code` and `message`.                   |
| `version`              | The version of the Dodgeball API that was used to make the request. Default is `v1`.                                              |
| `verification`         | Object representing the verification that was performed when this checkpoint was called.                                          |
| `verification.id`      | The ID of the verification that was created.                                                                                      |
| `verification.status`  | The current status of the verification. See [Verification Statuses](#verification-statuses) for possible values and descriptions. |
| `verification.outcome` | The outcome of the verification. See [Verification Outcomes](#verification-outcomes) for possible values and descriptions.        |

#### Verification Statuses

| Status     | Description                                                      |
| :--------- | :--------------------------------------------------------------- |
| `COMPLETE` | The verification was completed successfully.                     |
| `PENDING`  | The verification is currently processing.                        |
| `BLOCKED`  | The verification is waiting for input from the user.             |
| `FAILED`   | The verification encountered an error and was unable to proceed. |

#### Verification Outcomes

| Outcome    | Description                                                                                     |
| :--------- | :---------------------------------------------------------------------------------------------- |
| `APPROVED` | The request should be allowed to proceed.                                                       |
| `DENIED`   | The request should be denied.                                                                   |
| `PENDING`  | A determination on how to proceed has not been reached yet.                                     |
| `ERROR`    | The verification encountered an error and was unable to make a determination on how to proceed. |

#### Possible Checkpoint Responses

##### Approved

```ruby
checkpoint_response = {
  success: true,
  errors: [],
  version: "v1",
  verification: {
    id: "def456",
    status: "COMPLETE",
    outcome: "APPROVED"
  }
}
```

When a request is allowed to proceed, the verification `status` will be `COMPLETE` and `outcome` will be `APPROVED`.

##### Denied

```ruby
checkpoint_response = {
  success: true,
  errors: [],
  version: "v1",
  verification: {
    id: "def456",
    status: "COMPLETE",
    outcome: "DENIED"
  }
}
```

When a request is denied, verification `status` will be `COMPLETE` and `outcome` will be `DENIED`.

##### Pending

```ruby
checkpoint_response = {
  success: true,
  errors: [],
  version: "v1",
  verification: {
    id: "def456",
    status: "PENDING",
    outcome: "PENDING"
  }
}
```

If the verification is still processing, the `status` will be `PENDING` and `outcome` will be `PENDING`.

##### Blocked

```ruby
checkpoint_response = {
  success: true,
  errors: [],
  version: "v1",
  verification: {
    id: "def456",
    status: "BLOCKED",
    outcome: "PENDING"
  }
}
```

A blocked verification requires additional input from the user before proceeding. When a request is blocked, verification `status` will be `BLOCKED` and the `outcome` will be `PENDING`.

##### Undecided

```ruby
checkpoint_response = {
  success: true,
  errors: [],
  version: "v1",
  verification: {
    id: "def456",
    status: "COMPLETED",
    outcome: "PENDING"
  }
}
```

If the verification has finished, with no determination made on how to proceed, the verification `status` will be `COMPLETE` and the `outcome` will be `PENDING`.

##### Error

```ruby
checkpoint_response = {
  success: false,
  errors: [
    {
      code: 503,
      message: "[Service Name]: Service is unavailable"
    }
  ],
  version: "v1",
  verification: {
    id: "def456",
    status: "FAILED",
    outcome: "ERROR"
  }
}
```

If a verification encounters an error while processing (such as when a 3rd-party service is unavailable), the `success` flag will be false. The verification `status` will be `FAILED` and the `outcome` will be `ERROR`. The `errors` array will contain at least one object with a `code` and `message` describing the error(s) that occurred.

### useVerification

---

Sometimes additional input is required from the user before making a determination about how to proceed. For example, if a user should be required to perform 2FA before being allowed to proceed, the checkpoint response will contain a verification with `status` of `BLOCKED` and outcome of `PENDING`. In this scenario, you will want to return the verification to your frontend application. Inside your frontend application, you can pass the returned verification directly to the `dodgeball.handle_verification` method to automatically handle gathering additional input from the user. Continuing with our 2FA example, the user would be prompted to select a phone number and enter a code sent to that number. Once the additional input is received, the frontend application should simply send along the ID of the verification performed to your API. Passing that verification ID to the `verification_id` option will allow that verification to be used for this checkpoint instead of creating a new one. This prevents duplicate verifications being performed on the user.

**Important Note:** To prevent replay attacks, each verification ID can only be passed to `verification_id` once.

### Send a server-side event to track

---

You can store additional information about a user's journey by submitting tracking events from your server. This information will be added to the user's profile and is made available to checkpoints.

```ruby
dodgeball.event(event: {
  type: "EVENT_NAME", # Can be any string you choose
  data: {
    # Arbitrary data to track...
    transaction: {
      amount: 100,
      currency: 'USD',
    },
    paymentMethod: {
      token: 'ghi789'
    }
  }
  },
  source_token: "abc123...", # Obtained from the Dodgeball Client SDK, represents the device making the request
  session_id: "session_def456", # The current session ID of the request
  customer_id: "user_12345" # When you know the ID representing the user making the request in your database (ie after registration), pass it in here. Otherwise leave it blank.
)

```

| Parameter      | Required | Description                                                                                                                                                                    |
| :------------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `event`        | `true`   | The event to track.                                                                                                                                                            |
| `event.type`   | `true`   | A name representing where in the journey the user is.                                                                                                                          |
| `event.data`   | `false`  | Object containing arbitrary data to track.                                                                                                                                     |
| `source_token` | `false`  | A Dodgeball generated token representing the device making the request. Obtained from the [Dodgeball Trust Client SDK](https://npmjs.com/package/@dodgeball/trust-sdk-client). |
| `session_id`   | `true`   | The current session ID of the request.                                                                                                                                         |
| `customer_id`      | `false`  | When you know the ID representing the user making the request in your database (ie after registration), pass it in here. Otherwise leave it blank.                             |

## Contact Us

If you come across any issues while configuring or using Dodgeball, please feel free to [contact us](hello@dodgeballhq.com). We will be happy to help!

## Get Setup for Development and get a REPL

```bash
sudo gem update bundler
bundle install
rake console
```
