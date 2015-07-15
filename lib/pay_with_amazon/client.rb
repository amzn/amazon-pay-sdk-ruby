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
            options = {})
      @merchant_id = merchant_id
      @access_key = access_key
      @secret_key = secret_key
      @currency_code = options.fetch(:currency_code){:usd}.to_s.upcase
      @sandbox = options.fetch(:sandbox) { false }
      @sandbox_str = @sandbox ? 'OffAmazonPayments_Sandbox' : 'OffAmazonPayments'
      @region = options.fetch(:region){:na}
      @mws_endpoint = region_hash[@region] ? region_hash[@region] : raise("Invalid Region Code. (#{@region})")
      @platform_id = options.fetch(:platform_id){ nil }
      @throttle = options.fetch(:throttle){ true}
      @application_name = options.fetch(:application_name){ nil }
      @application_version = options.fetch(:application_version){ nil}
      @proxy_addr = options.fetch(:proxy_addr){ :ENV }
      @proxy_port = options.fetch(:proxy_port){ nil }
      @proxy_user = options.fetch(:proxy_user){ nil }
      @proxy_pass = options.fetch(:proxy_pass){ nil }

      @default_hash = {
        'AWSAccessKeyId' => @access_key,
        'SignatureMethod' => 'HmacSHA256',
        'SignatureVersion' => '2',
        'Timestamp' => Time.now.utc.iso8601,
        'Version' => PayWithAmazon::API_VERSION
      }

      @default_hash['PlatformId'] = @platform_id if @platform_id
    end

    # The GetServiceStatus operation returns the operational status of the Amazon Payments API
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
             options = {})
      parameters = {
        'Action' => 'CreateOrderReferenceForId',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'Id' => id,
        'IdType' => id_type
      }

      optional = {
        'InheritShippingAddress' => options.fetch(:inherit_shipping_address){ nil },
        'ConfirmNow' => options.fetch(:confirm_now){ nil},
        'OrderReferenceAttributes.OrderTotal.Amount' => options.fetch(:amount){ nil },
        'OrderReferenceAttributes.OrderTotal.CurrencyCode' => options.fetch(:currency_code){ @currency_code},
        'OrderReferenceAttributes.PlatformId' => options.fetch(:platform_id){ nil },
        'OrderReferenceAttributes.SellerNote' => options.fetch(:seller_note){ nil },
        'OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId' => options.fetch(:seller_order_id){ nil },
        'OrderReferenceAttributes.SellerOrderAttributes.StoreName' =>  options.fetch(:store_name){ nil },
        'OrderReferenceAttributes.SellerOrderAttributes.CustomInformation' => options.fetch(:custom_information){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})

      parameters = {
        'Action' => 'GetBillingAgreementDetails',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'AddressConsentToken' => options.fetch(:address_consent_token){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})
      parameters = {
        'Action' => 'SetBillingAgreementDetails',
        'SellerId' =>  options.fetch(:merchant_id){ @merchant_id},
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'BillingAgreementAttributes.PlatformId' =>  options.fetch(:platform_id){ nil },
        'BillingAgreementAttributes.SellerNote' =>  options.fetch(:seller_note){ nil },
        'BillingAgreementAttributes.SellerBillingAgreementAttributes.SellerBillingAgreementId' =>  options.fetch(:seller_billing_agreement_id){ nil },
        'BillingAgreementAttributes.SellerBillingAgreementAttributes.CustomInformation' =>  options.fetch(:custom_information){ nil },
        'BillingAgreementAttributes.SellerBillingAgreementAttributes.StoreName' =>  options.fetch(:store_name){ nil },
        'MWSAuthToken' =>  options.fetch(:mws_auth_token){ nil }
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
            options = {}
          )

      parameters = {
        'Action' => 'ConfirmBillingAgreement',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id},
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})

      parameters = {
        'Action' => 'ValidateBillingAgreement',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {}
            )

      parameters = {
        'Action' => 'AuthorizeOnBillingAgreement',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonBillingAgreementId' => amazon_billing_agreement_id,
        'AuthorizationReferenceId' => authorization_reference_id,
        'AuthorizationAmount.Amount' => amount,
        'AuthorizationAmount.CurrencyCode' => options.fetch(:currency_code){ @currency_code }
      }

      optional = {
        'SellerAuthorizationNote' => options.fetch(:seller_authorization_note){ nil },
        'TransactionTimeout' => options.fetch(:transaction_timeout){ nil },
        'CaptureNow' => options.fetch(:capture_now){ false },
        'SoftDescriptor' => options.fetch(:soft_descriptor){ nil },
        'SellerNote' => options.fetch(:seller_note){ nil },
        'PlatformId' => options.fetch(:platform_id){ nil },
        'SellerOrderAttributes.CustomInformation' =>  options.fetch(:custom_information){ nil },
        'SellerOrderAttributes.SellerOrderId' =>  options.fetch(:seller_order_id){ nil },
        'SellerOrderAttributes.StoreName' =>  options.fetch(:store_name){ nil },
        'InheritShippingAddress' =>  options.fetch(:inherit_shipping_address){ nil },
        'MWSAuthToken' =>  options.fetch(:mws_auth_token){ nil }
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
            options = {}
            )
      parameters = {
        'Action' => 'CloseBillingAgreement',
        'SellerId' => options.fetch(:merchant_id){ nil },
        'AmazonBillingAgreementId' => amazon_billing_agreement_id
      }

      optional = {
        'ClosureReason' => options.fetch(:closure_reason){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {}
            )

      parameters = {
        'Action' => 'GetOrderReferenceDetails',
        'SellerId' =>options.fetch(:merchant_id){ @merchant_id },
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'AddressConsentToken' => options.fetch(:address_consent_token){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {}
            )

      parameters = {
        'Action' => 'SetOrderReferenceDetails',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id},
        'AmazonOrderReferenceId' => amazon_order_reference_id,
        'OrderReferenceAttributes.OrderTotal.Amount' => amount,
        'OrderReferenceAttributes.OrderTotal.CurrencyCode' => options.fetch(:currency_code){ @currency_code }
      }

      optional = {
        'OrderReferenceAttributes.PlatformId' => options.fetch(:platform_id){ nil },
        'OrderReferenceAttributes.SellerNote' => options.fetch(:seller_note){ nil },
        'OrderReferenceAttributes.SellerOrderAttributes.SellerOrderId' => options.fetch(:seller_order_id){ nil },
        'OrderReferenceAttributes.SellerOrderAttributes.StoreName' => options.fetch(:store_name){ nil },
        'OrderReferenceAttributes.SellerOrderAttributes.CustomInformation' => options.fetch(:custom_information){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {}
            )

      parameters = {
        'Action' => 'ConfirmOrderReference',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})

      parameters = {
        'Action' => 'CancelOrderReference',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id},
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'CancelationReason' => options.fetch(:cancelation_reason){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
    # @optional provider_credit_details [Array of Hash]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def authorize(
            amazon_order_reference_id,
            authorization_reference_id,
            amount,
            options = {}
            )
      parameters = {
        'Action' => 'Authorize',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonOrderReferenceId' => amazon_order_reference_id,
        'AuthorizationReferenceId' => authorization_reference_id,
        'AuthorizationAmount.Amount' => amount,
        'AuthorizationAmount.CurrencyCode' =>  options.fetch(:currency_code){ @currency_code }
      }

      optional = {
        'SellerAuthorizationNote' =>  options.fetch(:seller_authorization_note){ nil },
        'TransactionTimeout' =>  options.fetch(:transaction_timeout){ nil },
        'CaptureNow' =>  options.fetch(:capture_now){ nil },
        'SoftDescriptor' =>  options.fetch(:soft_descriptor){ nil },
        'MWSAuthToken' =>  options.fetch(:mws_auth_token){ nil }
      }
      provider_credit_details =  options.fetch(:provider_credit_details){ nil }
      optional.merge!(set_provider_credit_details(provider_credit_details)) if provider_credit_details

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
            options = {})

      parameters = {
        'Action' => 'GetAuthorizationDetails',
        'SellerId' =>  options.fetch(:merchant_id){ @merchant_id },
        'AmazonAuthorizationId' => amazon_authorization_id
      }

      optional = {
        'MWSAuthToken' =>  options.fetch(:mws_auth_token){ nil }
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
    # @optional provider_credit_details [Array of Hash]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def capture(
            amazon_authorization_id,
            capture_reference_id,
            amount,
            options = {})

      parameters = {
        'Action' => 'Capture',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonAuthorizationId' => amazon_authorization_id,
        'CaptureReferenceId' => capture_reference_id,
        'CaptureAmount.Amount' => amount,
        'CaptureAmount.CurrencyCode' =>  options.fetch(:currency_code){ @currency_code }
      }

      optional = {
        'SellerCaptureNote' =>  options.fetch(:seller_capture_note){ nil },
        'SoftDescriptor' =>  options.fetch(:soft_descriptor){ nil },
        'MWSAuthToken' =>  options.fetch(:mws_auth_token){ nil }
      }

      provider_credit_details =  options.fetch(:provider_credit_details){ nil }
      optional.merge!(set_provider_credit_details(provider_credit_details)) if provider_credit_details

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
            options = {})

      parameters = {
        'Action' => 'GetCaptureDetails',
        'SellerId' => options(:merchant_id){ @merchant_id },
        'AmazonCaptureId' => amazon_capture_id
      }

      optional = {
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
    # @optional provider_credit_reversal_details [Array of Hash]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def refund(
            amazon_capture_id,
            refund_reference_id,
            amount,
            options = {})
      parameters = {
        'Action' => 'Refund',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonCaptureId' => amazon_capture_id,
        'RefundReferenceId' => refund_reference_id,
        'RefundAmount.Amount' => amount,
        'RefundAmount.CurrencyCode' => options.fetch(:currency_code){ @currency_code }
      }

      optional = {
        'SellerRefundNote' => options.fetch(:seller_refund_note){ nil },
        'SoftDescriptor' => options.fetch(:soft_descriptor){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
      }
      provider_credit_reversal_details  = options.fetch(:provider_credit_reversal_details){ nil }
      optional.merge!(set_provider_credit_reversal_details(provider_credit_reversal_details)) if provider_credit_reversal_details

      operation(parameters, optional)
    end

    # Returns the status of a particular refund
    # @see http://docs.developer.amazonservices.com/en_US/off_amazon_payments/OffAmazonPayments_GetRefundDetails.html
    # @param amazon_refund_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_refund_details(
            amazon_refund_id,
            options = {})

      parameters = {
        'Action' => 'GetRefundDetails',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonRefundId' => amazon_refund_id
      }

      optional = {
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})
      parameters = {
        'Action' => 'CloseAuthorization',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonAuthorizationId' => amazon_authorization_id
      }

      optional = {
        'ClosureReason' => options.fetch(:closure_reason){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})
      parameters = {
        'Action' => 'CloseOrderReference',
        'SellerId' => options.fetch(:merchant_id){ @merchant_id },
        'AmazonOrderReferenceId' => amazon_order_reference_id
      }

      optional = {
        'ClosureReason' => options.fetch(:closure_reason){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
      }

      operation(parameters, optional)
    end

    # @param amazon_provider_credit_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_provider_credit_details(
            amazon_provider_credit_id,
            options = {})

        parameters = {
          'Action' => 'GetProviderCreditDetails',
          'SellerId' => options.fetch(:merchant_id){ @merchant_id },
          'AmazonProviderCreditId' => amazon_provider_credit_id
        }

        optional = {
          'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
        }

        operation(parameters, optional)
    end

    # @param amazon_provider_credit_reversal_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def get_provider_credit_reversal_details(
            amazon_provider_credit_reversal_id,
            options = {})

        parameters = {
          'Action' => 'GetProviderCreditReversalDetails',
          'SellerId' => options.fetch(:merchant_id){ @merchant_id },
          'AmazonProviderCreditReversalId' => amazon_provider_credit_reversal_id
        }

        optional = {
          'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
            options = {})

      parameters = {
        'Action' => 'ReverseProviderCredit',
        'SellerId' => options.fetch(:merchant_id){ @merchat_id},
        'AmazonProviderCreditId' => amazon_provider_credit_id,
        'CreditReversalReferenceId' => credit_reversal_reference_id,
        'CreditReversalAmount.Amount' => amount,
        'CreditReversalAmount.CurrencyCode' => options.fetch(:currency_code){ @currency_code }
      }

      optional = {
        'CreditReversalNote' => options.fetch(:credit_reversal_note){ nil },
        'MWSAuthToken' => options.fetch(:mws_auth_token){ nil }
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
