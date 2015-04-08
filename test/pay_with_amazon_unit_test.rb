require 'test_helper'

class PayWithAmazonUnitTest < Minitest::Test

  MERCHANT_ID = 'MERCHANT_ID'
  ACCESS_KEY = 'ACCESS_KEY'
  SECRET_KEY = 'SECRET_KEY'
  SANDBOX = true
  AMAZON_ORDER_REFERENCE_ID = 'AMAZON_ORDER_REFERENCE_ID'
  AMAZON_BILLING_AGREEMENT_ID = 'AMAZON_BILLING_AGREEMENT_ID'
  AMOUNT = 'AMOUNT'
  AUTHORIZATION_REFERENCE_ID = 'AUTHORIZATION_REFERENCE_ID'
  CAPTURE_REFERENCE_ID = 'CAPTURE_REFERENCE_ID'
  REFUND_REFERENCE_ID = 'REFUND_REFERENCE_ID'

  HEADERS = {
    'Accept'=>'*/*',
    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'User-Agent'=>"Language=Ruby; ApplicationLibraryVersion=1.0.0; Platform=#{RUBY_PLATFORM}; MWSClientVersion=2013-01-01; ApplicationName=; ApplicationVersion="
  }

  IPN_HEADERS = { 'x-amz-sns-message-type' => 'Notification' }

  IPN_BODY = {
    'Type' => 'Type',
    'MessageId' => 'MessageId',
    'TopicArn' => 'TopicArn',
    'Message' => {
      'NotificationType' => 'NotificationType',
      'SellerId' => 'SellerId',
      'ReleaseEnvironment' => 'ReleaseEnvironment',
      'Version' => 'Version',
      'NotificationData' => 'NotificationData',
      'Timestamp' => 'Timestamp'
    }.to_json,
    'Timestamp' => 'Timestamp',
    'Signature' => 'Signature',
    'SignatureVersion' => 'SignatureVersion',
    'SigningCertURL' => 'https://test.com/test.pem',
    'UnsubscribeURL' => 'UnsubscribeURL',
  }.to_json

  def setup
    @client = PayWithAmazon::Client.new(MERCHANT_ID, ACCESS_KEY, SECRET_KEY, sandbox: SANDBOX)
    @ipn = PayWithAmazon::IpnHandler.new(IPN_HEADERS, IPN_BODY)
  end

  def test_operation
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Test&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.send :operation, {'Action' => 'Test'}, {}
    assert_equal(true, res.success)
  end

  def test_send_request
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Test&SignatureMethod=HmacSHA256&SignatureVersion=2&Version=2013-01-01"
    mws_endpoint = "mws.amazonservices.com"
    sandbox_str = "OffAmazonPayments_Sandbox"

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.send :send_request, mws_endpoint, sandbox_str, post_url
    assert_equal(true, res.success)
  end

  def test_send_request_error_500
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Test&SignatureMethod=HmacSHA256&SignatureVersion=2&Version=2013-01-01"
    mws_endpoint = "mws.amazonservices.com"
    sandbox_str = "OffAmazonPayments_Sandbox"

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}",
       :headers => HEADERS).to_return(:status => 500)

    error = assert_raises(RuntimeError) {
      @client.send :send_request, mws_endpoint, sandbox_str, post_url
    }
    assert_equal("InternalServerError", error.message)
  end

  def test_send_request_error_503
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Test&SignatureMethod=HmacSHA256&SignatureVersion=2&Version=2013-01-01"
    mws_endpoint = "mws.amazonservices.com"
    sandbox_str = "OffAmazonPayments_Sandbox"

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}",
       :headers => HEADERS).to_return(:status => 503)

    error = assert_raises(RuntimeError) {
      @client.send :send_request, mws_endpoint, sandbox_str, post_url
    }
    assert_equal("ServiceUnavailable or RequestThrottled", error.message)
  end

  def test_get_seconds_for_try_count
    value = @client.send :get_seconds_for_try_count, 1
    assert_equal(1, value)
  end

  def test_response
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Test&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200, :body => "<root><test>value</test></root>")

    res = @client.send :operation, {'Action' => 'Test'}, {}

    assert_equal("value", res.to_xml.root.elements[1].text)
    assert_equal("<root><test>value</test></root>", res.body)
    assert_equal("value", res.get_element("root","test"))
    assert_equal("200", res.code)
  end

  def test_response_error
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Test&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 404)

    res = @client.send :operation, {'Action' => 'Test'}, {}

    assert_equal(false, res.success)
  end

  def test_signature
    signature = @client.send :sign, "test signature code"
    assert_equal("VWty3pyWd3Ol4pw3L7nFQ%2FxI6SXXsV5T2aRdoNPVMg0%3D", signature)
  end

  def test_get_service_status
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=GetServiceStatus&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.get_service_status
    assert_equal(true, res.success)
  end

  def test_get_order_reference_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=GetOrderReferenceDetails&AmazonOrderReferenceId=#{AMAZON_ORDER_REFERENCE_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.get_order_reference_details(AMAZON_ORDER_REFERENCE_ID)
    assert_equal(true, res.success)
  end

  def test_set_order_reference_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=SetOrderReferenceDetails&AmazonOrderReferenceId=#{AMAZON_ORDER_REFERENCE_ID}&OrderReferenceAttributes.OrderTotal.Amount=#{AMOUNT}&OrderReferenceAttributes.OrderTotal.CurrencyCode=USD&OrderReferenceAttributes.SellerNote=seller_note&OrderReferenceAttributes.SellerOrderAttributes.CustomInformation=custom_information&OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId=seller_order_id&OrderReferenceAttributes.SellerOrderAttributes.StoreName=store_name&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    seller_note = 'seller_note'
    seller_order_id = 'seller_order_id'
    store_name = 'store_name'
    custom_information = 'custom_information'

    res = @client.set_order_reference_details(AMAZON_ORDER_REFERENCE_ID, AMOUNT, store_name: store_name, custom_information: custom_information, seller_note: seller_note, seller_order_id: seller_order_id)
    assert_equal(true, res.success)
  end

  def test_confirm_order_reference
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=ConfirmOrderReference&AmazonOrderReferenceId=#{AMAZON_ORDER_REFERENCE_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.confirm_order_reference(AMAZON_ORDER_REFERENCE_ID)
    assert_equal(true, res.success)
  end

  def test_authorize
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Authorize&AmazonOrderReferenceId=#{AMAZON_ORDER_REFERENCE_ID}&AuthorizationAmount.Amount=#{AMOUNT}&AuthorizationAmount.CurrencyCode=USD&AuthorizationReferenceId=#{AUTHORIZATION_REFERENCE_ID}&CaptureNow=capture_now&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&TransactionTimeout=transaction_timeout&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.authorize(AMAZON_ORDER_REFERENCE_ID, AUTHORIZATION_REFERENCE_ID, AMOUNT, capture_now: "capture_now", transaction_timeout: "transaction_timeout")
    assert_equal(true, res.success)
  end

  def test_get_authorization_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=GetAuthorizationDetails&AmazonAuthorizationId=amazon_authorization_id&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.get_authorization_details("amazon_authorization_id")
    assert_equal(true, res.success)
  end

  def test_close_authorization
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=CloseAuthorization&AmazonAuthorizationId=amazon_authorization_id&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.close_authorization("amazon_authorization_id")
    assert_equal(true, res.success)
  end

  def test_capture
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Capture&AmazonAuthorizationId=amazon_authorization_id&CaptureAmount.Amount=#{AMOUNT}&CaptureAmount.CurrencyCode=USD&CaptureReferenceId=#{CAPTURE_REFERENCE_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.capture("amazon_authorization_id", CAPTURE_REFERENCE_ID, AMOUNT)
    assert_equal(true, res.success)
  end

  def test_get_capture_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=GetCaptureDetails&AmazonCaptureId=amazon_capture_id&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.get_capture_details("amazon_capture_id")
    assert_equal(true, res.success)
  end

  def test_cancel_order_reference
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=CancelOrderReference&AmazonOrderReferenceId=#{AMAZON_ORDER_REFERENCE_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.cancel_order_reference(AMAZON_ORDER_REFERENCE_ID)
    assert_equal(true, res.success)
  end

  def test_close_order_reference
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=CloseOrderReference&AmazonOrderReferenceId=#{AMAZON_ORDER_REFERENCE_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.close_order_reference(AMAZON_ORDER_REFERENCE_ID)
    assert_equal(true, res.success)
  end

  def test_refund
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=Refund&AmazonCaptureId=amazon_capture_id&RefundAmount.Amount=#{AMOUNT}&RefundAmount.CurrencyCode=USD&RefundReferenceId=#{REFUND_REFERENCE_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.refund("amazon_capture_id", REFUND_REFERENCE_ID, AMOUNT)
    assert_equal(true, res.success)
  end

  def test_get_refund_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=GetRefundDetails&AmazonRefundId=amazon_refund_id&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.get_refund_details("amazon_refund_id")
    assert_equal(true, res.success)
  end

  def test_get_billing_agreement_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=GetBillingAgreementDetails&AmazonBillingAgreementId=#{AMAZON_BILLING_AGREEMENT_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.get_billing_agreement_details(AMAZON_BILLING_AGREEMENT_ID)
    assert_equal(true, res.success)
  end

  def test_set_billing_agreement_details
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=SetBillingAgreementDetails&AmazonBillingAgreementId=#{AMAZON_BILLING_AGREEMENT_ID}&BillingAgreementAttributes.SellerBillingAgreementAttributes.CustomInformation=custom_information&BillingAgreementAttributes.SellerBillingAgreementAttributes.SellerBillingAgreementId=seller_billing_agreement_id&BillingAgreementAttributes.SellerBillingAgreementAttributes.StoreName=store_name&BillingAgreementAttributes.SellerNote=seller_note&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    seller_note = 'seller_note'
    store_name = 'store_name'
    custom_information = 'custom_information'
    seller_billing_agreement_id = 'seller_billing_agreement_id'

    res = @client.set_billing_agreement_details(AMAZON_BILLING_AGREEMENT_ID, store_name: store_name, seller_billing_agreement_id: seller_billing_agreement_id, custom_information: custom_information, seller_note: seller_note)
    assert_equal(true, res.success)
  end

  def test_confirm_billing_agreement
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=ConfirmBillingAgreement&AmazonBillingAgreementId=#{AMAZON_BILLING_AGREEMENT_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.confirm_billing_agreement(AMAZON_BILLING_AGREEMENT_ID)
    assert_equal(true, res.success)
  end

  def test_validate_billing_agreement
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=ValidateBillingAgreement&AmazonBillingAgreementId=#{AMAZON_BILLING_AGREEMENT_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.validate_billing_agreement(AMAZON_BILLING_AGREEMENT_ID)
    assert_equal(true, res.success)
  end

  def test_authorize_on_billing_agreement
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=AuthorizeOnBillingAgreement&AmazonBillingAgreementId=#{AMAZON_BILLING_AGREEMENT_ID}&AuthorizationAmount.Amount=#{AMOUNT}&AuthorizationAmount.CurrencyCode=USD&AuthorizationReferenceId=#{AUTHORIZATION_REFERENCE_ID}&CaptureNow=capture_now&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&TransactionTimeout=transaction_timeout&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.authorize_on_billing_agreement(AMAZON_BILLING_AGREEMENT_ID, AUTHORIZATION_REFERENCE_ID, AMOUNT, capture_now: "capture_now", transaction_timeout: "transaction_timeout")
    assert_equal(true, res.success)
  end

  def test_create_order_reference_for_id
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=CreateOrderReferenceForId&ConfirmNow=confirm_now&Id=#{AMAZON_BILLING_AGREEMENT_ID}&IdType=id_type&OrderReferenceAttributes.OrderTotal.Amount=#{AMOUNT}&OrderReferenceAttributes.OrderTotal.CurrencyCode=USD&OrderReferenceAttributes.SellerNote=seller_note&OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId=seller_order_id&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.create_order_reference_for_id(AMAZON_BILLING_AGREEMENT_ID, "id_type", confirm_now: "confirm_now", amount: AMOUNT, seller_note: "seller_note", seller_order_id: "seller_order_id")
    assert_equal(true, res.success)
  end

  def test_close_billing_agreement
    post_url = "AWSAccessKeyId=#{ACCESS_KEY}&Action=CloseBillingAgreement&AmazonBillingAgreementId=#{AMAZON_BILLING_AGREEMENT_ID}&SellerId=#{MERCHANT_ID}&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{@client.send :custom_escape, Time.now.utc.iso8601}&Version=2013-01-01"
    post_body = ["POST", "mws.amazonservices.com", "/OffAmazonPayments_Sandbox/2013-01-01", post_url].join("\n")

    stub_request(:post, "https://mws.amazonservices.com/OffAmazonPayments_Sandbox/2013-01-01").with(:body => "#{post_url}&Signature=#{@client.send :sign, post_body}",
       :headers => HEADERS).to_return(:status => 200)

    res = @client.close_billing_agreement(AMAZON_BILLING_AGREEMENT_ID)
    assert_equal(true, res.success)
  end

  def test_ipn_helpers
    assert_equal('Type', @ipn.type)
    assert_equal('MessageId', @ipn.message_id)
    assert_equal('TopicArn', @ipn.topic_arn)
    assert_equal("{\"NotificationType\":\"NotificationType\",\"SellerId\":\"SellerId\",\"ReleaseEnvironment\":\"ReleaseEnvironment\",\"Version\":\"Version\",\"NotificationData\":\"NotificationData\",\"Timestamp\":\"Timestamp\"}", @ipn.message)
    assert_equal('Timestamp', @ipn.timestamp)
    assert_equal('Signature', @ipn.signature)
    assert_equal('SignatureVersion', @ipn.signature_version)
    assert_equal('https://test.com/test.pem', @ipn.signing_cert_url)
    assert_equal('UnsubscribeURL', @ipn.unsubscribe_url)
    assert_equal('NotificationType', @ipn.notification_type)
    assert_equal('SellerId', @ipn.seller_id)
    assert_equal('ReleaseEnvironment', @ipn.environment)
    assert_equal('Version', @ipn.version)
    assert_equal('NotificationData', @ipn.notification_data)
    assert_equal('Timestamp', @ipn.message_timestamp)
  end

  def test_validate_header
    @ipn.send :validate_header
    assert_equal('Notification', @ipn.headers['x-amz-sns-message-type'])
  end

  def test_validate_subject_error
    error = assert_raises(PayWithAmazon::IpnWasNotAuthenticError) {
      @ipn.send :validate_subject, [['CN','CN'],['CN','CN'],['CN','CN'],['CN','CN'],['CN','CN']]
    }
    assert_equal("Error - Unable to verify certificate subject issued by Amazon", error.message )
  end

  def test_https_get
    stub_request(:get, "https://test.com/test.pem").with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).to_return(:status => 200)

    res = @ipn.send :https_get, 'https://test.com/test.pem'

    assert_equal('200', res.code)
  end

  def test_download_cert_error
    error = assert_raises(PayWithAmazon::IpnWasNotAuthenticError) {
      @ipn.send :download_cert, 'https://test.com/test.pem'
    }

    assert_equal("Error - certificate is not hosted at AWS URL (https): https://test.com/test.pem", error.message)
  end

  def test_canonical_string
    res = @ipn.send :canonical_string
    assert_equal("Message\n{\"NotificationType\":\"NotificationType\",\"SellerId\":\"SellerId\",\"ReleaseEnvironment\":\"ReleaseEnvironment\",\"Version\":\"Version\",\"NotificationData\":\"NotificationData\",\"Timestamp\":\"Timestamp\"}\nMessageId\nMessageId\nTimestamp\nTimestamp\nTopicArn\nTopicArn\nType\nType\n", res)
  end

end
