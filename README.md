# Login and Pay with Amazon Ruby SDK
Login and Pay with Amazon API Integration

# Install

```
gem install pay_with_amazon
```
or add the following in your Gemfile:

```ruby
gem 'pay_with_amazon'
```
```
Bundle Install
```

## Requirements

* Ruby 2.0.0 or higher

## Quick Start

Instantiating the client:

```ruby
require 'pay_with_amazon'

# Your Login and Pay with Amazon keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = PayWithAmazon::Client.new(
  merchant_id,
  access_key,
  secret_key
)
```

### Testing in Sandbox Mode

The sandbox parameter is defaulted to false if not specified:

```ruby
require 'pay_with_amazon'

# Your Login and Pay with Amazon keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = PayWithAmazon::Client.new(
  merchant_id,
  access_key,
  secret_key,
  sandbox: true
)
```


### Adjusting Region and Currency Code

```ruby
require 'pay_with_amazon'

# Your Login and Pay with Amazon keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = PayWithAmazon::Client.new(
  merchant_id,
  access_key,
  secret_key,
  region: :eu,
  currency_code: :gbp
)
```

### Making an API Call

Below is an example on how to make the GetOrderReferenceDetails API call:

```ruby
require 'pay_with_amazon'

# Your Login and Pay with Amazon keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = PayWithAmazon::Client.new(
  merchant_id,
  access_key,
  secret_key,
  sandbox: true
)

# These values are grabbed from the Login and Pay
# with Amazon Address and Wallet widgets
amazon_order_reference_id = 'AMAZON_ORDER_REFERENCE_ID'
address_consent_token = 'ADDRESS_CONSENT_TOKEN'

client.get_order_reference_details(
  amazon_order_reference_id,
  address_consent_token: address_consent_token
)

```

### Response Parsing

```ruby
# These values are grabbed from the Login and Pay
# with Amazon Address and Wallet widgets
amazon_order_reference_id = 'AMAZON_ORDER_REFERENCE_ID'
address_consent_token = 'ADDRESS_CONSENT_TOKEN'

response = client.get_order_reference_details(
  amazon_order_reference_id,
  address_consent_token: address_consent_token
)

# This will return the original response body as a String
response.body

# This will return a REXML object
response.to_xml

# The 'get_element' method allows quick conversion to REXML
# and parsing for the xml element. This will return a
# String value from the specified element.
xpath = 'XPath for the node you would like to extract'
element = 'Node/Element name you would like to extract the value from'
response.get_element(xpath, element)

# This will return the status code of the response
response.code

# This will return true or false depending on the status code
response.success
```

### Instant Payment Notification Verification and Parsing

```ruby
# This can be placed in your controller for a method
# that is configured to receive a "POST" IPN from Amazon.
headers = request.headers
body = request.body.read

ipn = PayWithAmazon::IpnHandler.new(headers, body)

# This will return "true" if the notification is a  
# valid IPN from Amazon
ipn.authentic?

# The following are methods used to extract the necessary
# data from the IPN
ipn.type
ipn.message_id
ipn.topic_arn
ipn.message
ipn.timestamp
ipn.signature
ipn.signature_version
ipn.signing_cert_url
ipn.unsubscribe_url
ipn.notification_type
ipn.seller_id
ipn.environment
ipn.version
ipn.notification_data
ipn.message_timestamp

```
