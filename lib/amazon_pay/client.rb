# rubocop:disable Metrics/MethodLength, Metrics/LineLength, Metrics/AbcSize, Metrics/ClassLength, Metrics/ParameterLists, Style/AccessorMethodName

require 'time'
require 'logger'
require 'stringio'

module AmazonPay
  # AmazonPay API
  #
  # This client allows you to make all the necessary API calls
  # to integrate with AmazonPay. This client only
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
      :application_version,
      :log_enabled,
      :log_file_name,
      :log_level
    )

    attr_accessor(
      :proxy_addr,
      :proxy_port,
      :proxy_user,
      :proxy_pass
    )

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
    # @optional log_enabled [Boolean] Default: false
    # @optional log_file_name [String]
    # @optional log_level [Symbol] Default: DEBUG
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
      log_enabled: false,
      log_file_name: nil,
      log_level: :DEBUG
    )
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
        'Version' => AmazonPay::API_VERSION
      }

      @log_enabled = log_enabled
      @log_level = log_level
      @log_file_name = log_file_name

      @default_hash['PlatformId'] = @platform_id if @platform_id
    end

    # The GetServiceStatus operation returns the operational status of the AmazonPay API
    # section of Amazon Marketplace Web Service (Amazon MWS). Status values are GREEN, GREEN_I, YELLOW, and RED.
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752110
    def get_service_status
      parameters = {
        'Action' => 'GetServiceStatus'
      }

      operation(parameters, {})
    end

    # Creates an order reference for the given object
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751670
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
    # @optional supplementary_data [String]
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
      supplementary_data: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
        'OrderReferenceAttributes.SellerOrderAttributes.SupplementaryData' => supplementary_data,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns details about the Billing Agreement object and its current state
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751690
    # @param amazon_billing_agreement_id [String]
    # @optional address_consent_token [String]
    # @optional access_token [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]

    def get_billing_agreement_details(
      amazon_billing_agreement_id,
      address_consent_token: nil,
      access_token: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'GetBillingAgreementDetails',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        # Preseving address_consent_token for backwards compatibility
        # AccessToken returns all data in AddressConsentToken plus new data
        # You cannot pass both address_consent_token and access_token in
        # the same call or you will encounter a 400/"AmbiguousToken" error
        'AccessToken' => access_token,
        'AddressConsentToken' => address_consent_token,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Sets billing agreement details such as a description of the agreement
    # and other information about the seller.
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751700
    # @param amazon_billing_agreement_id [String]
    # @optional platform_id [String]
    # @optional seller_note [String]
    # @optional seller_billing_agreement_id [String]
    # @optional custom_information [String]
    # @optional store_name [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    # @optional billing_agreement_type [String] - one of CustomerInitiatedTransaction or MerchantInitiatedTransaction
    # @optional subscription_amount [String]
    # @optional subscription_currency_code [String]

    def set_billing_agreement_details(
      amazon_billing_agreement_id,
      platform_id: nil,
      seller_note: nil,
      seller_billing_agreement_id: nil,
      custom_information: nil,
      store_name: nil,
      merchant_id: @merchant_id,
      billing_agreement_type: nil,
      subscription_amount: nil,
      subscription_currency_code: @currency_code,
      mws_auth_token: nil
    )

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
        'BillingAgreementAttributes.BillingAgreementType' => billing_agreement_type,
        'BillingAgreementAttributes.SubscriptionAmount.Amount' => subscription_amount,
        'BillingAgreementAttributes.SubscriptionAmount.CurrencyCode' => subscription_currency_code,
        'MWSAuthToken' => mws_auth_token
      }

      optional['BillingAgreementAttributes.SubscriptionAmount.CurrencyCode'] = nil if subscription_amount.nil?

      operation(parameters, optional)
    end

    # Confirms that the billing agreement is free of constraints and all
    # required information has been set on the billing agreement
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751710
    # @param amazon_billing_agreement_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    # @optional success_url [String]
    # @optional failure_url [String]
    def confirm_billing_agreement(
      amazon_billing_agreement_id,
      merchant_id: @merchant_id,
      success_url: nil,
      failure_url: nil,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'ConfirmBillingAgreement',
        'SellerId' => merchant_id,
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'SuccessUrl' => success_url,
        'FailureUrl' => failure_url,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Validates the status of the BillingAgreement object and the payment
    # method associated with it
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751720
    # @param amazon_billing_agreement_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def validate_billing_agreement(
      amazon_billing_agreement_id,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751940
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
    # @optional supplementary_data [String]
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
      supplementary_data: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
        'SellerOrderAttributes.SupplementaryData' => supplementary_data,
        'InheritShippingAddress' => inherit_shipping_address,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Confirms that you want to terminate the billing agreement with the buyer
    # and that you do not expect to create any new order references or
    # authorizations on this billing agreement
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751950
    # @param amazon_billing_agreement_id [String]
    # @optional closure_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def close_billing_agreement(
      amazon_billing_agreement_id,
      closure_reason: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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

    # Allows the search of any Amazon Pay order made using secondary
    # seller order IDs generated manually, a solution provider, or a custom
    # order fulfillment service.
    # @param query_id [String]
    # @param query_id_type [String]
    # @optional created_time_range_start [String]
    # @optional created_time_range_end [String]
    # @optional sort_order [String]
    # @optional page_size [Integer]
    # @optional order_reference_status_list_filter Array[String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def list_order_reference(
      query_id,
      query_id_type,
      created_time_range_start: nil,
      created_time_range_end: nil,
      sort_order: nil,
      page_size: nil,
      order_reference_status_list_filter: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      payment_domain = payment_domain_hash[@region]

      parameters = {
        'Action' => 'ListOrderReference',
        'SellerId' => merchant_id,
        'QueryId' => query_id,
        'QueryIdType' => query_id_type
      }

      optional = {
        'CreatedTimeRange.StartTime' => created_time_range_start,
        'CreatedTimeRange.EndTime' => created_time_range_end,
        'SortOrder' => sort_order,
        'PageSize' => page_size,
        'PaymentDomain' => payment_domain,
        'MWSAuthToken' => mws_auth_token
      }

      if order_reference_status_list_filter
        order_reference_status_list_filter.each_with_index do |val, index|
          optional_key = "OrderReferenceStatusListFilter.OrderReferenceStatus.#{index + 1}"
          optional[optional_key] = val
        end
      end

      operation(parameters, optional)
    end

    # When ListOrderReference returns multiple pages
    # you can continue by using the NextPageToken returned
    # by ListOrderReference
    # @param next_page_token [String]
    def list_order_reference_by_next_token(next_page_token)
      parameters = {
        'Action' => 'ListOrderReferenceByNextToken',
        'SellerId' => @merchant_id,
        'NextPageToken' => next_page_token
      }

      operation(parameters, {})
    end

    # Returns status of the merchant
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_merchant_account_status(
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'GetMerchantAccountStatus',
        'SellerId' => merchant_id
      }

      optional = {
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Returns details about the Order Reference object and its current state
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751970
    # @param amazon_order_reference_id [String]
    # @optional address_consent_token [String]
    # @optional access_token [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_order_reference_details(
      amazon_order_reference_id,
      address_consent_token: nil,
      access_token: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'GetOrderReferenceDetails',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        # Preseving address_consent_token for backwards compatibility
        # AccessToken returns all data in AddressConsentToken plus new data
        'AccessToken' => access_token || address_consent_token,
        'MWSAuthToken' => mws_auth_token
      }

      operation(parameters, optional)
    end

    # Sets order reference details such as the order total and a description
    # for the order
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751960
    # @param amazon_order_reference_id [String]
    # @param amount [String]
    # @optional currency_code [String]
    # @optional platform_id [String]
    # @optional seller_note [String]
    # @optional seller_order_id [String]
    # @optional request_payment_authorization [Boolean]
    # @optional store_name [String]
    # @optional order_item_categories Array[String]
    # @optional custom_information [String]
    # @optional supplementary_data [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def set_order_reference_details(
      amazon_order_reference_id,
      amount,
      currency_code: @currency_code,
      platform_id: nil,
      seller_note: nil,
      seller_order_id: nil,
      request_payment_authorization: nil,
      store_name: nil,
      order_item_categories: nil,
      custom_information: nil,
      supplementary_data: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'SetOrderReferenceDetails',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id,
        'OrderReferenceAttributes.OrderTotal.Amount' => amount,
        'OrderReferenceAttributes.OrderTotal.CurrencyCode' => currency_code
      }

      optional = {
        'OrderReferenceAttributes.PlatformId' => platform_id,
        'OrderReferenceAttributes.RequestPaymentAuthorization' => request_payment_authorization,
        'OrderReferenceAttributes.SellerNote' => seller_note,
        'OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId' => seller_order_id,
        'OrderReferenceAttributes.SellerOrderAttributes.StoreName' => store_name,
        'OrderReferenceAttributes.SellerOrderAttributes.CustomInformation' => custom_information,
        'OrderReferenceAttributes.SellerOrderAttributes.SupplementaryData' => supplementary_data,
        'MWSAuthToken' => mws_auth_token
      }

      if order_item_categories
        optional.merge!(
          get_categories_list(
            'OrderReferenceAttributes',
            order_item_categories
          )
        )
      end

      operation(parameters, optional)
    end

    # Sets order attributes such as the order total and a description
    # for the order
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751960
    # @param amazon_order_reference_id [String]
    # @optional amount [String]
    # @optional currency_code [String]
    # @optional platform_id [String]
    # @optional seller_note [String]
    # @optional seller_order_id [String]
    # @optional request_payment_authorization [Boolean]
    # @optional store_name [String]
    # @optional order_item_categories Array[String]
    # @optional custom_information [String]
    # @optional supplementary_data [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def set_order_attributes(
      amazon_order_reference_id,
      amount: nil,
      currency_code: @currency_code,
      platform_id: nil,
      seller_note: nil,
      seller_order_id: nil,
      payment_service_provider_id: nil,
      payment_service_provider_order_id: nil,
      request_payment_authorization: nil,
      store_name: nil,
      order_item_categories: nil,
      custom_information: nil,
      supplementary_data: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'SetOrderAttributes',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'OrderAttributes.OrderTotal.Amount' => amount,
        'OrderAttributes.OrderTotal.CurrencyCode' => currency_code,
        'OrderAttributes.PlatformId' => platform_id,
        'OrderAttributes.SellerNote' => seller_note,
        'OrderAttributes.SellerOrderAttributes.SellerOrderId' => seller_order_id,
        'OrderAttributes.PaymentServiceProviderAttributes.PaymentServiceProviderId' => payment_service_provider_id,
        'OrderAttributes.PaymentServiceProviderAttributes.PaymentServiceProviderOrderId' => payment_service_provider_order_id,
        'OrderAttributes.RequestPaymentAuthorization' => request_payment_authorization,
        'OrderAttributes.SellerOrderAttributes.StoreName' => store_name,
        'OrderAttributes.SellerOrderAttributes.CustomInformation' => custom_information,
        'OrderAttributes.SellerOrderAttributes.SupplementaryData' => supplementary_data,
        'MWSAuthToken' => mws_auth_token
      }

      optional['OrderAttributes.OrderTotal.CurrencyCode'] = nil if amount.nil?

      if order_item_categories
        optional.merge!(
          get_categories_list(
            'OrderAttributes',
            order_item_categories
          )
        )
      end

      operation(parameters, optional)
    end

    # Confirms that the order reference is free of constraints and all required
    # information has been set on the order reference
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751980
    # @param amazon_order_reference_id [String]
    # @optional success_url [String]
    # @optional failure_url [String]
    # @optional authorization_amount [String]
    # @optional currency_code [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def confirm_order_reference(
      amazon_order_reference_id,
      success_url: nil,
      failure_url: nil,
      authorization_amount: nil,
      currency_code: @currency_code,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      parameters = {
        'Action' => 'ConfirmOrderReference',
        'SellerId' => merchant_id,
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'SuccessUrl' => success_url,
        'FailureUrl' => failure_url,
        'AuthorizationAmount.Amount' => authorization_amount,
        'AuthorizationAmount.CurrencyCode' => currency_code,
        'MWSAuthToken' => mws_auth_token
      }

      optional['AuthorizationAmount.CurrencyCode'] = nil if authorization_amount.nil?

      operation(parameters, optional)
    end

    # Cancels a previously confirmed order reference
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751990
    # @param amazon_order_reference_id [String]
    # @optional cancelation_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def cancel_order_reference(
      amazon_order_reference_id,
      cancelation_reason: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752010
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
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752030
    # @param amazon_authorization_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_authorization_details(
      amazon_authorization_id,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752040
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
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752060
    # @param amazon_capture_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_capture_details(
      amazon_capture_id,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752080
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
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752100
    # @param amazon_refund_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_refund_details(
      amazon_refund_id,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752070
    # @param amazon_authorization_id [String]
    # @optional closure_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def close_authorization(
      amazon_authorization_id,
      closure_reason: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
    # @see https://pay.amazon.com/documentation/apireference/201751630#201752000
    # @param amazon_order_reference_id [String]
    # @optional closure_reason [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def close_order_reference(
      amazon_order_reference_id,
      closure_reason: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

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
      mws_auth_token: nil
    )

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
      mws_auth_token: nil
    )

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
      mws_auth_token: nil
    )

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
        jp: 'mws.amazonservices.jp',
        uk: 'mws-eu.amazonservices.com',
        de: 'mws-eu.amazonservices.com',
        eu: 'mws-eu.amazonservices.com',
        us: 'mws.amazonservices.com',
        na: 'mws.amazonservices.com'
      }
    end

    def payment_domain_hash
      {
        jp: 'FE_JPY',
        uk: 'EU_GBP',
        de: 'EU_EUR',
        eu: 'EU_EUR',
        us: 'NA_USD',
        na: 'NA_USD'
      }
    end

    # This method builds the provider credit details hash
    # that will be combined with either the authorize or capture
    # API call.
    def set_provider_credit_details(provider_credit_details)
      member_details = {}
      provider_credit_details.each_with_index do |val, index|
        member = index + 1
        member_details["ProviderCreditList.member.#{member}.ProviderId"] = val[:provider_id]
        member_details["ProviderCreditList.member.#{member}.CreditAmount.Amount"] = val[:amount]
        member_details["ProviderCreditList.member.#{member}.CreditAmount.CurrencyCode"] = val[:currency_code]
      end

      member_details
    end

    # This method builds the provider credit reversal
    # details hash that will be combined with the refund
    # API call.
    def set_provider_credit_reversal_details(provider_credit_reversal_details)
      member_details = {}
      provider_credit_reversal_details.each_with_index do |val, index|
        member = index + 1
        member_details["ProviderCreditReversalList.member.#{member}.ProviderId"] = val[:provider_id]
        member_details["ProviderCreditReversalList.member.#{member}.CreditReversalAmount.Amount"] = val[:amount]
        member_details["ProviderCreditReversalList.member.#{member}.CreditReversalAmount.CurrencyCode"] = val[:currency_code]
      end

      member_details
    end

    def get_categories_list(attribute_key, categories)
      list = {}

      categories.each_with_index do |val, index|
        list.merge!("#{attribute_key}.SellerOrderAttributes.OrderItemCategories.OrderItemCategory.#{index + 1}" => val)
      end

      list
    end

    def operation(parameters, optional)
      AmazonPay::Request.new(
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
        @application_version,
        @log_enabled,
        @log_file_name,
        @log_level
      ).send_post
    end
  end
end
