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
bundle install
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

### One Time Transaction API Flow

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

# To get the buyers full address if shipping/tax
# calculations are needed you can use the following
# API call to obtain the order reference details.
client.get_order_reference_details(
  amazon_order_reference_id,
  address_consent_token: address_consent_token
)

amount = '10.00'

# Make the SetOrderReferenceDetails API call to
# configure the Amazon Order Reference Id.
# There are additional optional parameters that
# are not used below.
client.set_order_reference_details(
  amazon_order_reference_id,
  amount,
  currency_code: 'USD', # Default: USD
  seller_note: 'Your Seller Note',
  seller_order_id: 'Your Seller Order Id',
  store_name: 'Your Store Name'
)

# Make the ConfirmOrderReference API call to
# confirm the details set in the API call
# above.
client.confirm_order_reference(amazon_order_reference_id)

# Set a unique id for your current authorization
# of this payment.
authorization_reference_id = 'Your Unique Id'

# Make the Authorize API call to authorize the
# transaction. You can also capture the amount
# in this API call or make the Capture API call
# separately. There are additional optional
# parameters not used below.
response = client.authorize(
  amazon_order_reference_id,
  authorization_reference_id,
  amount,
  currency_code: 'USD', # Default: USD
  seller_authorization_note: 'Your Authorization Note',
  transaction_timeout: 0, # Set to 0 for synchronous mode
  capture_now: true # Set this to true if you want to capture the amount in the same API call
)

# You will need the Amazon Authorization Id from the
# Authorize API response if you decide to make the
# Capture API call separately.
amazon_authorization_id = response.get_element('AuthorizeResponse/AuthorizeResult/AuthorizationDetails','AmazonAuthorizationId')

# Set a unique id for your current capture of
# this payment.
capture_reference_id = 'Your Unique Id'

# Make the Capture API call if you did not set the
# 'capture_now' parameter to 'true'. There are
# additional optional parameters that are not used
# below.
client.capture(
  amazon_authorization_id,
  capture_reference_id,
  amount,
  currency_code: 'USD', # Default: USD
  seller_capture_note: 'Your Capture Note'
)

# Close the order reference once your one time
# transaction is complete.
client.close_order_reference(amazon_order_reference_id)

```

### Subscriptions API Flow

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
amazon_billing_agreement_id = 'AMAZON_BILLING_AGREEMENT_ID'
address_consent_token = 'ADDRESS_CONSENT_TOKEN'

# To get the buyers full address, if shipping/tax
# calculations are needed, you can use the following
# API call to obtain the billing agreement details.
client.get_billing_agreement_details(
  amazon_billing_agreement_id,
  address_consent_token: address_consent_token
)

# Next you will need to set the various details
# for this subscription with the following API call.
# There are additional optional parameters that
# are not used below.
client.set_billing_agreement_details(
  amazon_billing_agreement_id,
  seller_note: 'Your Seller Note',
  seller_billing_agreement_id: 'Your Transaction Id',
  store_name: 'Your Store Name',
  custom_information: 'Additional Information'
)

# Make the ConfirmBillingAgreement API call to confirm
# the Amazon Billing Agreement Id with the details set above.
# Be sure that everything is set correctly above before
# confirming.
client.confirm_billing_agreement(amazon_billing_agreement_id)

# The following API call is not needed at this point, but
# can be used in the future when you need to validate that
# the payment method is still valid with the associated billing
# agreement id.
client.validate_billing_agreement(amazon_billing_agreement_id)

# Set the amount for your first authorization.
amount = '10.00'

# Set a unique authorization reference id for your
# first transaction on the billing agreement.
authorization_reference_id = 'Your Unique Id'

# Now you can authorize your first transaction on the
# billing agreement id. Every month you can make the
# same API call to continue charging your buyer
# with the 'capture_now' parameter set to true. You can
# also make the Capture API call separately. There are
# additional optional parameters that are not used
# below.
response = client.authorize_on_billing_agreement(
  amazon_billing_agreement_id,
  authorization_reference_id,
  amount,
  currency_code: 'USD', # Default: USD
  seller_authorization_note: 'Your Authorization Note',
  transaction_timeout: 0, # Set to 0 for synchronous mode
  capture_now: true, # Set this to true if you want to capture the amount in the same API call
  seller_note: 'Your Seller Note',
  seller_order_id: 'Your Order Id',
  store_name: 'Your Store Name',
  custom_information: 'Additional Information'
)

# You will need the Amazon Authorization Id from the
# AuthorizeOnBillingAgreement API response if you decide
# to make the Capture API call separately.
amazon_authorization_id = response.get_element('AuthorizeOnBillingAgreementResponse/AuthorizeOnBillingAgreementResult/AuthorizationDetails','AmazonAuthorizationId')

# Set a unique id for your current capture of
# this transaction.
capture_reference_id = 'Your Unique Id'

# Make the Capture API call if you did not set the
# 'capture_now' parameter to 'true'. There are
# additional optional parameters that are not used
# below.
client.capture(
  amazon_authorization_id,
  capture_reference_id,
  amount,
  currency_code: 'USD', # Default: USD
  seller_capture_note: 'Your Capture Note'
)

# The following API call should not be made until you
# are ready to terminate the billing agreement.
client.close_billing_agreement(
  amazon_billing_agreement_id,
  closure_reason: 'Reason For Closing'
)

```

### Get User Info API

This API call allows you to obtain user profile information
once a user has logged into your application using
their Amazon credentials.

```ruby
require 'pay_with_amazon'

# Your client id is located in your Seller
# Central account.
client_id = 'Your Client Id'

user = PayWithAmazon::GetUser.new(
  client_id,
  region: :na, # Default: :na
  sandbox: true # Default: false
)

# The access token is available in the return URL
# parameters after a user has logged in.
access_token = 'User Access Token'

# Make the 'get_user_info' api call.
user_info = user.get_user_info(access_token)

name = user_info['name']
email = user_info['email']
user_id = user_info['user_id']

```
