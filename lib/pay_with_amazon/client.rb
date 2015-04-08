require 'uri'
require 'net/http'
require 'net/https'
require 'base64'
require 'openssl'
require 'time'

module PayWithAmazon

  # Pay with Amazon API
  #
  # This client allows you to make all the necessary API calls
  # to integrate with Login and Pay with Amazon. This client only
  # uses the standard Ruby library and is not dependant on Rails.
  class Client

    MAX_RETRIES = 4

    attr_reader(
      :merchant_id,
      :access_key,
      :secret_key,
      :sandbox,
      :currency_code,
      :region,
      :platform_id,
      :throttle,
      :application_name,
      :application_version)

    attr_accessor(
      :sandbox,
      :proxy_addr,
      :proxy_port,
      :proxy_user,
      :proxy_pass)

    # API keys are located at:
    # @see htps://sellercentral.amazon.com
    # @param merchant_id [String]
    # @param access_key [String]
    # @param secret_key [String]
    # @optional sandbox [Boolean] Default: false
    # @optional currency_code [Symbol] Default: :usd
    # @optional region [Symbol] Default: :na
    # @optional platform_id [String] Default: nil
    # @optional throttle [Boolean]
    # @optional application_name [String]
    # @optional application_version [String]
    # @optional proxy_addr [String]
    # @optional proxy_port [String]
    # @optional proxy_user [String]
    # @optional proxy_pass [String]
    def initialize(
            merchant_id,
            access_key,
            secret_key,
            sandbox: false,
            currency_code: :usd,
            region: :na,
            platform_id: nil,
            throttle: true,
            application_name: nil,
            application_version: nil,
            proxy_addr: :ENV,
            proxy_port: nil,
            proxy_user: nil,
            proxy_pass: nil)

      @merchant_id = merchant_id
      @access_key = access_key
      @secret_key = secret_key
      @currency_code = currency_code.to_s.upcase
      @sandbox = sandbox
      @sandbox_str = @sandbox ? 'OffAmazonPayments_Sandbox' : 'OffAmazonPayments'
      @region = region
      @mws_endpoint = region_hash[@region] ? region_hash[@region] : raise("Invalid Region Code. (#{@region})")
      @platform_id = platform_id
      @throttle = throttle
      @application_name = application_name
      @application_version = application_version
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      @proxy_user = proxy_user
      @proxy_pass = proxy_pass

      @default_hash = {
        'AWSAccessKeyId' => @access_key,
        'SignatureMethod' => 'HmacSHA256',
        'SignatureVersion' => '2',
        'Timestamp' => Time.now.utc.iso8601,
        'Version' => PayWithAmazon::API_VERSION
      }

      @default_hash['PlatformId'] = @platform_id if @platform_id
    end

    # Returns the operational status of the Off-Amazon Payments API section
    # The GetServiceStatus operation returns the operational status of the Off-Amazon Payments API
    # section of Amazon Marketplace Web Service (Amazon MWS). Status values are GREEN, GREEN_I, YELLOW, and RED.
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetServiceStatus.html
    def get_service_status
      parameters = {
        'Action' => 'GetServiceStatus'
      }

      operation(parameters, {})
    end

    # Creates an order reference for the given object
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_CreateOrderReferenceForId.html
    # @param id [String]
    # @param id_type [String]
    # @optional inherit_shipping_address [Boolean]
    # @optional confirm_now [Boolean]
    # @optional amount [String] (required when confirm_now is set to true)
    # @optional currency_code [String]
    # @optional platform_id [String]
    # @optional seller_note [String]
    # @optional seller_order_id [String]
    # @optional store_name [String]
    # @optional custom_information [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def create_order_reference_for_id(
            id,
            id_type,
            inherit_shipping_address: nil,
            confirm_now: nil,
            amount: nil,
            currency_code: @currency_code,
            platform_id: nil,
            seller_note: nil,
            seller_order_id: nil,
            store_name: nil,
            custom_information: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'CreateOrderReferenceForId',
        'SellerId' => merchant_id,
        'Id' => id,
        'IdType' => id_type
      }

      optional = {
        'InheritShippingAddress' => inherit_shipping_address,
        'ConfirmNow' => confirm_now,
        'OrderReferenceAttributes.OrderTotal.Amount' => amount,
        'OrderReferenceAttributes.OrderTotal.CurrencyCode' => currency_code,
        'OrderReferenceAttributes.PlatformId' => platform_id,
        'OrderReferenceAttributes.SellerNote' => seller_note,
        'OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId' => seller_order_id,
        'OrderReferenceAttributes.SellerOrderAttributes.StoreName' => store_name,
        'OrderReferenceAttributes.SellerOrderAttributes.CustomInformation' => custom_information,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns details about the Billing Agreement object and its current state
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetBillingAgreementDetails.html
    # @param amazon_billing_agreement_id [String]
    # @optional address_consent_token [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_billing_agreement_details(
            amazon_billing_agreement_id,
            address_consent_token: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'GetBillingAgreementDetails',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'AddressConsentToken' => address_consent_token,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Sets billing agreement details such as a description of the agreement
    # and other information about the seller.
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_SetBillingAgreementDetails.html
    # @param amazon_billing_agreement_id [String]
    # @optional platform_id [String]
    # @optional seller_note [String]
    # @optional seller_billing_agreement_id [String]
    # @optional custom_information [String]
    # @optional store_name [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def set_billing_agreement_details(
            amazon_billing_agreement_id,
            platform_id: nil,
            seller_note: nil,
            seller_billing_agreement_id: nil,
            custom_information: nil,
            store_name: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'SetBillingAgreementDetails',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'BillingAgreementAttributes.PlatformId' => platform_id,
        'BillingAgreementAttributes.SellerNote' => seller_note,
        'BillingAgreementAttributes.SellerBillingAgreementAttributes.SellerBillingAgreementId' => seller_billing_agreement_id,
        'BillingAgreementAttributes.SellerBillingAgreementAttributes.CustomInformation' => custom_information,
        'BillingAgreementAttributes.SellerBillingAgreementAttributes.StoreName' => store_name,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Confirms that the billing agreement is free of constraints and all
    # required information has been set on the billing agreement
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_ConfirmBillingAgreement.html
    # @param amazon_billing_agreement_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def confirm_billing_agreement(
            amazon_billing_agreement_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'ConfirmBillingAgreement',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Validates the status of the BillingAgreement object and the payment
    # method associated with it
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_ValidateBillingAgreement.html
    # @param amazon_billing_agreement_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def validate_billing_agreement(
            amazon_billing_agreement_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'ValidateBillingAgreement',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Reserves a specified amount against the payment method(s) stored in the
    # billing agreement
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_AuthorizeOnBillingAgreement.html
    # @param amazon_billing_agreement_id [String]
    # @param authorization_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_authorization_note [String]
    # @optional transaction_timeout [Integer]
    # @optional capture_now [Boolean]
    # @optional soft_descriptor [String]
    # @optional seller_note [String]
    # @optional platform_id [String]
    # @optional custom_information [String]
    # @optional seller_order_id [String]
    # @optional store_name [String]
    # @optional inherit_shipping_address [Boolean]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def authorize_on_billing_agreement(
            amazon_billing_agreement_id,
            authorization_reference_id,
            amount,
            currency_code: @currency_code,
            seller_authorization_note: nil,
            transaction_timeout: nil,
            capture_now: false,
            soft_descriptor: nil,
            seller_note: nil,
            platform_id: nil,
            custom_information: nil,
            seller_order_id: nil,
            store_name: nil,
            inherit_shipping_address: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'AuthorizeOnBillingAgreement',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id,
        'AuthorizationReferenceId' => authorization_reference_id,
        'AuthorizationAmount.Amount' => amount,
        'AuthorizationAmount.CurrencyCode' => currency_code
      }

      optional = {
        'SellerAuthorizationNote' => seller_authorization_note,
        'TransactionTimeout' => transaction_timeout,
        'CaptureNow' => capture_now,
        'SoftDescriptor' => soft_descriptor,
        'SellerNote' => seller_note,
        'PlatformId' => platform_id,
        'SellerOrderAttributes.CustomInformation' => custom_information,
        'SellerOrderAttributes.SellerOrderId' => seller_order_id,
        'SellerOrderAttributes.StoreName' => store_name,
        'InheritShippingAddress' => inherit_shipping_address,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Confirms that you want to terminate the billing agreement with the buyer
    # and that you do not expect to create any new order references or
    # authorizations on this billing agreement
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_CloseBillingAgreement.html
    # @param amazon_billing_agreement_id [String]
    # @optional closure_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def close_billing_agreement(
            amazon_billing_agreement_id,
            closure_reason: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'CloseBillingAgreement',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'ClosureReason' => closure_reason,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns details about the Order Reference object and its current state
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetOrderReferenceDetails.html
    # @param amazon_order_reference_id [String]
    # @optional address_consent_token [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_order_reference_details(
            amazon_order_reference_id,
            address_consent_token: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'GetOrderReferenceDetails',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'AddressConsentToken' => address_consent_token,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Sets order reference details such as the order total and a description
    # for the order
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_SetOrderReferenceDetails.html
    # @param amazon_order_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional platform_id [String]
    # @optional seller_note [String]
    # @optional seller_order_id [String]
    # @optional store_name [String]
    # @optional custom_information [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def set_order_reference_details(
            amazon_order_reference_id,
            amount,
            currency_code: @currency_code,
            platform_id: nil,
            seller_note: nil,
            seller_order_id: nil,
            store_name: nil,
            custom_information: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'SetOrderReferenceDetails',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id,
        'OrderReferenceAttributes.OrderTotal.Amount' => amount,
        'OrderReferenceAttributes.OrderTotal.CurrencyCode' => currency_code
      }

      optional = {
        'OrderReferenceAttributes.PlatformId' => platform_id,
        'OrderReferenceAttributes.SellerNote' => seller_note,
        'OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId' => seller_order_id,
        'OrderReferenceAttributes.SellerOrderAttributes.StoreName' => store_name,
        'OrderReferenceAttributes.SellerOrderAttributes.CustomInformation' => custom_information,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Confirms that the order reference is free of constraints and all required
    # information has been set on the order reference
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_ConfirmOrderReference.html
    # @param amazon_order_reference_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def confirm_order_reference(
            amazon_order_reference_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'ConfirmOrderReference',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Cancels a previously confirmed order reference
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_CancelOrderReference.html
    # @param amazon_order_reference_id [String]
    # @optional cancelation_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def cancel_order_reference(
            amazon_order_reference_id,
            cancelation_reason: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'CancelOrderReference',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'CancelationReason' => cancelation_reason,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Reserves a specified amount against the payment method(s) stored in the
    # order reference
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_Authorize.html
    # @param amazon_order_reference_id [String]
    # @param authorization_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_authorization_note [String]
    # @optional transaction_timeout [Integer]
    # @optional capture_now [Boolean]
    # @optional soft_descriptor [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def authorize(
            amazon_order_reference_id,
            authorization_reference_id,
            amount,
            currency_code: @currency_code,
            seller_authorization_note: nil,
            transaction_timeout: nil,
            capture_now: nil,
            soft_descriptor: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'Authorize',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id,
        'AuthorizationReferenceId' => authorization_reference_id,
        'AuthorizationAmount.Amount' => amount,
        'AuthorizationAmount.CurrencyCode' => currency_code
      }

      optional = {
        'SellerAuthorizationNote' => seller_authorization_note,
        'TransactionTimeout' => transaction_timeout,
        'CaptureNow' => capture_now,
        'SoftDescriptor' => soft_descriptor,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns the status of a particular authorization and the total amount
    # captured on the authorization
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetAuthorizationDetails.html
    # @param amazon_authorization_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_authorization_details(
            amazon_authorization_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'GetAuthorizationDetails',
        'SellerId' => merchant_id,
        'AmazonAuthorizationId' => amazon_authorization_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Captures funds from an authorized payment instrument.
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_Capture.html
    # @param amazon_authorization_id [String]
    # @param capture_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_capture_note [String]
    # @optional soft_descriptor [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def capture(
            amazon_authorization_id,
            capture_reference_id,
            amount,
            currency_code: @currency_code,
            seller_capture_note: nil,
            soft_descriptor: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'Capture',
        'SellerId' => merchant_id,
        'AmazonAuthorizationId' => amazon_authorization_id,
        'CaptureReferenceId' => capture_reference_id,
        'CaptureAmount.Amount' => amount,
        'CaptureAmount.CurrencyCode' => currency_code
      }

      optional = {
        'SellerCaptureNote' => seller_capture_note,
        'SoftDescriptor' => soft_descriptor,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns the status of a particular capture and the total amount refunded
    # on the capture
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetCaptureDetails.html
    # @param amazon_capture_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_capture_details(
            amazon_capture_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'GetCaptureDetails',
        'SellerId' => merchant_id,
        'AmazonCaptureId' => amazon_capture_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Refunds a previously captured amount
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_Refund.html
    # @param amazon_capture_id [String]
    # @param refund_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_refund_note [String]
    # @optional soft_descriptor [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def refund(
            amazon_capture_id,
            refund_reference_id,
            amount,
            currency_code: @currency_code,
            seller_refund_note: nil,
            soft_descriptor: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'Refund',
        'SellerId' => merchant_id,
        'AmazonCaptureId' => amazon_capture_id,
        'RefundReferenceId' => refund_reference_id,
        'RefundAmount.Amount' => amount,
        'RefundAmount.CurrencyCode' => currency_code
      }

      optional = {
        'SellerRefundNote' => seller_refund_note,
        'SoftDescriptor' => soft_descriptor,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns the status of a particular refund
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetRefundDetails.html
    # @param amazon_refund_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_refund_details(
            amazon_refund_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'GetRefundDetails',
        'SellerId' => merchant_id,
        'AmazonRefundId' => amazon_refund_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Closes an authorization
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_CloseAuthorization.html
    # @param amazon_authorization_id [String]
    # @optional closure_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def close_authorization(
            amazon_authorization_id,
            closure_reason: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'CloseAuthorization',
        'SellerId' => merchant_id,
        'AmazonAuthorizationId' => amazon_authorization_id
      }

      optional = {
        'ClosureReason' => closure_reason,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Confirms that an order reference has been fulfilled (fully or partially)
    # and that you do not expect to create any new authorizations on this
    # order reference
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_CloseOrderReference.html
    # @param amazon_order_reference_id [String]
    # @optional closure_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def close_order_reference(
            amazon_order_reference_id,
            closure_reason: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'CloseOrderReference',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'ClosureReason' => closure_reason,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    private

    def region_hash
      {
        :jp => 'mws.amazonservices.jp',
        :uk => 'mws-eu.amazonservices.com',
        :de => 'mws-eu.amazonservices.com',
        :eu => 'mws-eu.amazonservices.com',
        :us => 'mws.amazonservices.com',
        :na => 'mws.amazonservices.com'
      }
    end

    # This method combines the required and optional
    # parameters to generate the post url, sign the post body,
    # and send the post request.
    def operation(parameters, optional)
      optional.map { |k, v| parameters[k] = v unless v.nil? }
      parameters = @default_hash.merge(parameters)
      post_url = parameters.sort.map { |k, v| "#{k}=#{ custom_escape(v) }" }.join("&")
      post_body = ["POST", "#{@mws_endpoint}", "/#{@sandbox_str}/#{PayWithAmazon::API_VERSION}", post_url].join("\n")
      post_url += "&Signature=" + sign(post_body)
      send_request(@mws_endpoint, @sandbox_str, post_url)
    end

    # This method signs the post body request that is being sent
    # using the secret key provided.
    def sign(post_body)
      custom_escape(Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @secret_key, post_body)))
    end

    # This method performs the post to the MWS end point.
    # It will retry three times after the initial post if
    # the status code comes back as either 500 or 503.
    def send_request(mws_endpoint, sandbox_str, post_url)
      uri = URI("https://#{mws_endpoint}/#{sandbox_str}/#{PayWithAmazon::API_VERSION}")
      https = Net::HTTP.new(uri.host, uri.port, @proxy_addr, @proxy_port, @proxy_user, @proxy_pass)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      user_agent = {"User-Agent" => "Language=Ruby; ApplicationLibraryVersion=#{PayWithAmazon::VERSION}; Platform=#{RUBY_PLATFORM}; MWSClientVersion=#{PayWithAmazon::API_VERSION}; ApplicationName=#{@application_name}; ApplicationVersion=#{@application_version}"}
      tries = 0
      begin
        response = https.post(uri.path, post_url, user_agent)
        if @throttle.eql?(true)
          if response.code.eql?('500')
            raise 'InternalServerError'
          elsif response.code.eql?('503')
            raise 'ServiceUnavailable or RequestThrottled'
          end
        end
        PayWithAmazon::Response.new(response)
      rescue => error
        tries += 1
        sleep(get_seconds_for_try_count(tries))
        retry if tries < MAX_RETRIES
        raise error.message
      end
    end

    def get_seconds_for_try_count(try_count)
      seconds = { 1=>1, 2=>4, 3=>10, 4=>0 }
      seconds[try_count]
    end

    def custom_escape(val)
      val.to_s.gsub(/([^\w.~-]+)/) do
        "%" + $1.unpack("H2" * $1.bytesize).join("%").upcase
      end
    end

  end

end
