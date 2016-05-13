require 'time'

module PayWithAmazon

  # Pay with Amazon API
  #
  # This client allows you to make all the necessary API calls
  # to integrate with Login and Pay with Amazon. This client only
  # uses the standard Ruby library and is not dependant on Rails.
  class Client

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
    # @see https://sellercentral.amazon.com
    # @param merchant_id [String]
    # @param access_key [String]
    # @param secret_key [String]
    # @optional sandbox [Boolean] Default: false
    # @optional currency_code [Symbol] Default: :usd
    # @optional region [Symbol] Default: :na
    # @optional platform_id [String] Default: nil
    # @optional throttle [Boolean] Default: true
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
            proxy_pass: nil,
            mws_auth_token: nil)

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
      @mws_auth_token = mws_auth_token

      @default_hash = {
        'AWSAccessKeyId' => @access_key,
        'SignatureMethod' => 'HmacSHA256',
        'SignatureVersion' => '2',
        'Timestamp' => Time.now.utc.iso8601,
        'Version' => PayWithAmazon::API_VERSION
      }

      @default_hash['PlatformId'] = @platform_id if @platform_id
      @default_hash['MWSAuthToken'] = @mws_auth_token if @mws_auth_token
    end

    # The GetServiceStatus operation returns the operational status of the Amazon Payments API
    # section of Amazon Marketplace Web Service (Amazon MWS). Status values are GREEN, GREEN_I, YELLOW, and RED.
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752110
    def get_service_status
      parameters = {
        'Action' => 'GetServiceStatus'
      }

      operation(parameters, {})
    end

    # Creates an order reference for the given object
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751670
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751690
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751700
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751710
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751720
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751940
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751950
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751970
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751960
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751980
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201751990
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752010
    # @param amazon_order_reference_id [String]
    # @param authorization_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_authorization_note [String]
    # @optional transaction_timeout [Integer]
    # @optional capture_now [Boolean]
    # @optional soft_descriptor [String]
    # @optional provider_credit_details [Array of Hash]
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
            provider_credit_details: nil,
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

      optional.merge!(set_provider_credit_details(provider_credit_details)) if provider_credit_details

      operation(parameters, optional)
    end

    # Returns the status of a particular authorization and the total amount
    # captured on the authorization
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752030
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752040
    # @param amazon_authorization_id [String]
    # @param capture_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_capture_note [String]
    # @optional soft_descriptor [String]
    # @optional provider_credit_details [Array of Hash]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def capture(
            amazon_authorization_id,
            capture_reference_id,
            amount,
            currency_code: @currency_code,
            seller_capture_note: nil,
            soft_descriptor: nil,
            provider_credit_details: nil,
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

      optional.merge!(set_provider_credit_details(provider_credit_details)) if provider_credit_details

      operation(parameters, optional)
    end

    # Returns the status of a particular capture and the total amount refunded
    # on the capture
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752060
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752080
    # @param amazon_capture_id [String]
    # @param refund_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional seller_refund_note [String]
    # @optional soft_descriptor [String]
    # @optional provider_credit_reversal_details [Array of Hash]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def refund(
            amazon_capture_id,
            refund_reference_id,
            amount,
            currency_code: @currency_code,
            seller_refund_note: nil,
            soft_descriptor: nil,
            provider_credit_reversal_details: nil,
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

      optional.merge!(set_provider_credit_reversal_details(provider_credit_reversal_details)) if provider_credit_reversal_details

      operation(parameters, optional)
    end

    # Returns the status of a particular refund
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752100
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752070
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
    # @see https://payments.amazon.com/documentation/apireference/201751630#201752000
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

    # @param amazon_provider_credit_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_provider_credit_details(
            amazon_provider_credit_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

        parameters = {
          'Action' => 'GetProviderCreditDetails',
          'SellerId' => merchant_id,
          'AmazonProviderCreditId' => amazon_provider_credit_id
        }

        optional = {
          'MWSAuthToken' => mws_auth_token
        }

        operation(parameters, optional)
    end

    # @param amazon_provider_credit_reversal_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_provider_credit_reversal_details(
            amazon_provider_credit_reversal_id,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

        parameters = {
          'Action' => 'GetProviderCreditReversalDetails',
          'SellerId' => merchant_id,
          'AmazonProviderCreditReversalId' => amazon_provider_credit_reversal_id
        }

        optional = {
          'MWSAuthToken' => mws_auth_token
        }

        operation(parameters, optional)
    end

    # @param amazon_provider_credit_id [String]
    # @param credit_reversal_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional credit_reversal_note [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def reverse_provider_credit(
            amazon_provider_credit_id,
            credit_reversal_reference_id,
            amount,
            currency_code: @currency_code,
            credit_reversal_note: nil,
            merchant_id: @merchant_id,
            mws_auth_token: nil)

      parameters = {
        'Action' => 'ReverseProviderCredit',
        'SellerId' => merchant_id,
        'AmazonProviderCreditId' => amazon_provider_credit_id,
        'CreditReversalReferenceId' => credit_reversal_reference_id,
        'CreditReversalAmount.Amount' => amount,
        'CreditReversalAmount.CurrencyCode' => currency_code
      }

      optional = {
        'CreditReversalNote' => credit_reversal_note,
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

    # This method builds the provider credit details hash
    # that will be combined with either the authorize or capture
    # API call.
    def set_provider_credit_details(provider_credit_details)
      member_details = {}
      provider_credit_details.each_with_index { |val, index|
        member = index + 1
        member_details["ProviderCreditList.member.#{member}.ProviderId"] = val[:provider_id]
        member_details["ProviderCreditList.member.#{member}.CreditAmount.Amount"] = val[:amount]
        member_details["ProviderCreditList.member.#{member}.CreditAmount.CurrencyCode"] = val[:currency_code]
      }

      return member_details
    end

    # This method builds the provider credit reversal
    # details hash that will be combined with the refund
    # API call.
    def set_provider_credit_reversal_details(provider_credit_reversal_details)
      member_details = {}
      provider_credit_reversal_details.each_with_index { |val, index|
        member = index + 1
        member_details["ProviderCreditReversalList.member.#{member}.ProviderId"] = val[:provider_id]
        member_details["ProviderCreditReversalList.member.#{member}.CreditReversalAmount.Amount"] = val[:amount]
        member_details["ProviderCreditReversalList.member.#{member}.CreditReversalAmount.CurrencyCode"] = val[:currency_code]
      }

      return member_details
    end

    def operation(parameters, optional)
      PayWithAmazon::Request.new(
          parameters,
          optional,
          @default_hash,
          @mws_endpoint,
          @sandbox_str,
          @secret_key,
          @proxy_addr,
          @proxy_port,
          @proxy_user,
          @proxy_pass,
          @throttle,
          @application_name,
          @application_version).send_post
    end

  end

end
