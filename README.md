# Amazon Pay Ruby SDK
Amazon Pay API Integration

# Install

```
gem install amazon_pay
```
or add the following in your Gemfile:

```ruby
gem 'amazon_pay'
```
```
bundle install
```

## Requirements

* Ruby 2.0.0 or higher

## Quick Start

Instantiating the client:

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key
)
```

### Testing in Sandbox Mode

The sandbox parameter is defaulted to false if not specified:

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key,
  sandbox: true
)
```


### Adjusting Region and Currency Code

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
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
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key,
  sandbox: true
)

# These values are grabbed from the Amazon Pay
# Address and Wallet widgets
amazon_order_reference_id = 'AMAZON_ORDER_REFERENCE_ID'
address_consent_token = 'ADDRESS_CONSENT_TOKEN'

client.get_order_reference_details(
  amazon_order_reference_id,
  address_consent_token: address_consent_token
)

```

Below is an example on how to query using the Seller Order ID using the
ListOrderReference API call:

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key
)

seller_order_id = 'merchant_id:Test 4321'
# These are examples of input 
# for the option values
query_id = '1234-example-order'
query_id_type = 'SellerOrderId'
created_time_range_start_time = '2017-09-20T17:39:27.925Z'
created_time_range_end_time = '2017-09-25T17:39:27.925Z'
sort_order = 'Descending'
order_reference_status_list_filter = ['canceled', 'open', 'closed']
page_size = 1

response = client.list_order_reference(
  query_id,
  query_id_type,
  created_time_range_start: created_time_range_start_time,
  created_time_range_end: created_time_range_end_time,
  sort_order: sort_order,
  page_size: page_size,
  order_reference_status_list_filter: order_reference_status_list_filter,
  mws_auth_token: nil
  )

```

Below is an example on how to query using the next token received
from ListOrderReference using the ListOrderReferenceByNextToken 
API call:

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key
)

response = client.list_order_reference_by_next_token(
  'eyJuZXh0UGFnZVRva2VuIjoiQUFBQUFBQUFBQUZXL0x3dE50TDBTUWhla29JVk5VNWgvbURhSWJXc1E2MnlVdzVuaURCTURFN2g4U0xja3EweWpCSlY4S2pVRHFJWC9wcDBKOG8rMnJDcFREa2xjWjViVmJweFhPS2xuYUJXL0pQeTB4UGIwNjlUU3dlcnVSSHB5TUREMUV2aiswM3pvY3FWbkRZL0p3VTVpWUV4cUdaeGpYbzg0WVI2NkVmek9tbTRjVUZSbDNJL2ZOOC9kMWRuMkMyaWxaMy9nNlRtU2cvMG9CdTJ2U1FVVy9rcThxc1dmS1dQNkFQaGhKK08xOFlmVko5NS9WWFRPeXliMWJVdEl0U3h5K2FlYlN1YXBoWHZybGdqR3BERE1zeFhsRFozLzlsc2hPNE1lZTQ2MlVIU3lndFVjN0htLzQ2NFFzVTlMRmE0N0UrZ05hOVRSeU1XMTJ5ZU1Mc3ZydkdES2lTcFVuSTB1Rk83RnZFK01GbzdOQUtsWUhSbDVsSUgrSy9LYmJhQ2lsLzZxaFdwbkJjK3J6WmQrOVg0ZmRrWG9YcWpXK3oyVTdUTUZWVjFkaEVnOHZ0cmgvaGxHb0N6ZUZiSVg3SWVNOCtwS0pkbWtPdjlpUUlxbTNYM1hZQXBTamtEMUtWNnNaTWsvNkphREpQazhoanVUVjFMV1JiZVREeVQ2eElBeVRJeFIrOXZkTlozYW1YdHA4cklxRGNSMzh2aTdwTi9UYXo3WFR2Y1c0aDF3UEFCOTVNU3J5WmJTYUpVMjEybVZhclZwdFZ4aEMyWlRBVUR6MkltRlZUbU05bXZRL1ZWNEhWSExQZE9kQ1BrVFVWWHFZNGo4Z3Q3YTlUdkhKWlFyQzd2Q2o1djUrc0RNNkZXT0gwWWZscW1wV0NZc2ZGMko0V0dFcnkvS3ZMQTZHWm0xVitxVmVwd21lZEx5bDgzZXdFS0JUbDhVTkVTZklIRW5ETVdaRHBORmdXNmhVaUNzWTFZbEdwemxnZUpUbUpVR1lBQXRrY3BxQjMrb29rRCtBTWRPM05lZFpQeVYvM1d2M1B6dTI1VkVHQVNWRU90RDVieTl3WUUxczQ1bU83alZWa1JJakxlMndnQUNJTTlVc3hnZXlGRDZOY1dNclk5VWZ2UTNiKzZibjdqU0ljcTYrdkgrWG1Zb0V4ekM4K1pHWDVJcnlUUmVpRjBGMW1vRHNTUkowVW1kNGxyVldNNmNJTE0rOHFpb0IzMGF6dXdQNnZDb3VsVkZwWS9vK0o0Wmc9PSIsIm1hcmtldHBsYWNlSWQiOiJBM0JYQjBZTjNYSDE3SCJ9'
  )

```

Below is an example on how to enable Logging for the SDK:

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key,
  log_enabled: true,
  # If you don't specify a log file like
  # the example below, logging will be
  # output to the standard out stream
  log_file_name: 'log.txt',
  # Currently only the debug level has been
  # implemented in the SDK. This is done
  # by default.
  log_level: :debug
)

```

### Response Parsing

```ruby
# These values are grabbed from the Amazon Pay
# Address and Wallet widgets
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

ipn = AmazonPay::IpnHandler.new(headers, body)

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

### Standard One Time Transaction API Flow

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key,
  sandbox: true
)

# These values are grabbed from the Amazon Pay
# Address and Wallet widgets
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
# payment transaction is complete.
client.close_order_reference(amazon_order_reference_id)

```

### Subscriptions API Flow

```ruby
require 'amazon_pay'

# Your Amazon Pay keys are
# available in your Seller Central account
merchant_id = 'YOUR_MERCHANT_ID'
access_key = 'YOUR_ACCESS_KEY'
secret_key = 'YOUR_SECRET_KEY'

client = AmazonPay::Client.new(
  merchant_id,
  access_key,
  secret_key,
  sandbox: true
)

# These values are grabbed from the Amazon Pay
# Address and Wallet widgets
amazon_billing_agreement_id = 'AMAZON_BILLING_AGREEMENT_ID'
address_consent_token = 'ADDRESS_CONSENT_TOKEN'

# To get the buyers full address if shipping/tax
# calculations are needed you can use the following
# API call to obtain the billing agreement details.
client.get_billing_agreement_details(
  amazon_billing_agreement_id,
  address_consent_token
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
client.confirm_billing_agreement(
  amazon_billing_agreement_id
)

# The following API call is not needed at this point, but
# can be used in the future when you need to validate that
# the payment method is still valid with the associated billing
# agreement id.
client.validate_billing_agreement(
  amazon_billing_agreement_id
)

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
client.authorize_on_billing_agreement(
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
amazon_authorization_id = res.get_element('AuthorizeOnBillingAgreementResponse/AuthorizeOnBillingAgreementResult/AuthorizationDetails','AmazonAuthorizationId')

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

# The following API call should not be made until you
# are ready to terminate the billing agreement.
client.close_billing_agreement(
  amazon_billing_agreement_id,
  closure_reason: 'Reason For Closing'
)

```


### Get Login Profile API

This API call allows you to obtain user profile information
once a user has logged into your application using
their Amazon credentials.

```ruby
require 'amazon_pay'

# Your client id is located in your Seller
# Central account.
client_id = 'Your Client Id'

login = AmazonPay::Login.new(
  client_id,
  region: :na, # Default: :na
  sandbox: true # Default: false
)

# The access token is available in the return URL
# parameters after a user has logged in.
access_token = 'User Access Token'

# Make the 'get_user_info' api call.
profile = login.get_login_profile(access_token)

name = profile['name']
email = profile['email']
user_id = profile['user_id']

```
