module AmazonPay
  # This will extend the client class to add additional
  # helper methods that combine core API calls.
  class Client
    # This method combines multiple API calls to perform
    # a complete transaction with minimum requirements.
    # @param amazon_reference_id [String]
    # @param authorization_reference_id [String]
    # @param charge_amount [String]
    # @optional charge_currency_code [String]
    # @optional charge_note [String]
    # @optional charge_order [String]
    # @optional store_name [String]
    # @optional custom_information [String]
    # @optional soft_descriptor [String]
    # @optional platform_id [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def charge(
      amazon_reference_id,
      authorization_reference_id,
      charge_amount,
      charge_currency_code: @currency_code,
      charge_note: nil,
      charge_order_id: nil,
      store_name: nil,
      custom_information: nil,
      soft_descriptor: nil,
      platform_id: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      if is_order_reference?(amazon_reference_id)
        response = call_order_reference_api(
          amazon_reference_id,
          authorization_reference_id,
          charge_amount,
          charge_currency_code,
          charge_note,
          charge_order_id,
          store_name,
          custom_information,
          soft_descriptor,
          platform_id,
          merchant_id,
          mws_auth_token
        )
        return response
      end

      if is_billing_agreement?(amazon_reference_id)
        response = call_billing_agreement_api(
          amazon_reference_id,
          authorization_reference_id,
          charge_amount,
          charge_currency_code,
          charge_note,
          charge_order_id,
          store_name,
          custom_information,
          soft_descriptor,
          platform_id,
          merchant_id,
          mws_auth_token
        )
        return response
      end
    end

    # Modify order attributes such as CustomInformation
    # for the order
    # This is a convenience function for set_order_attributes to prevent accidentally passing
    # extra variables that can't be modified ater Amazon Order Reference (ORO) is confirmed.
    # @see https://pay.amazon.com/documentation/apireference/201751630#201751960
    # @param amazon_order_reference_id [String]
    # @optional request_payment_authorization [Boolean]
    # @optional seller_note [String]
    # @optional seller_order_id [String]
    # @optional store_name [String]
    # @optional custom_information [String]
    # @optional merchant_id [String]
    # @optional mws_auth_token [String]
    def modify_order_attributes(
      amazon_order_reference_id,
      seller_note: nil,
      seller_order_id: nil,
      payment_service_provider_id: nil,
      payment_service_provider_order_id: nil,
      request_payment_authorization: nil,
      store_name: nil,
      custom_information: nil,
      merchant_id: @merchant_id,
      mws_auth_token: nil
    )

      set_order_attributes(amazon_order_reference_id,
        # amount:(This value can't be modified after order is confirmed so it isn't passed to set_order_attributes)
        # currency_code:(This value can't be modified after order is confirmed so it isn't passed to set_order_attributes)
        # platform_id:(This value can't be modified after order is confirmed so it isn't passed to set_order_attributes)
        seller_note: seller_note,
        seller_order_id: seller_order_id,
        payment_service_provider_id: payment_service_provider_id,
        payment_service_provider_order_id: payment_service_provider_order_id,
        request_payment_authorization: request_payment_authorization,
        store_name: store_name,
        # order_item_categories:(This value can't be modified after order is confirmed so it isn't passed to set_order_attributes)
        custom_information: custom_information,
        merchant_id: merchant_id,
        mws_auth_token: mws_auth_token
      )
    end

    private

    def call_order_reference_api(
      amazon_reference_id,
      authorization_reference_id,
      charge_amount,
      charge_currency_code,
      charge_note,
      charge_order_id,
      store_name,
      custom_information,
      soft_descriptor,
      platform_id,
      merchant_id,
      mws_auth_token
    )

      response = set_order_reference_details(
        amazon_reference_id,
        charge_amount,
        currency_code: charge_currency_code,
        platform_id: platform_id,
        seller_note: charge_note,
        seller_order_id: charge_order_id,
        store_name: store_name,
        custom_information: custom_information,
        merchant_id: merchant_id,
        mws_auth_token: mws_auth_token
      )
      if response.success
        response = confirm_order_reference(
          amazon_reference_id,
          merchant_id: merchant_id,
          mws_auth_token: mws_auth_token
        )
        if response.success
          response = authorize(
            amazon_reference_id,
            authorization_reference_id,
            charge_amount,
            currency_code: charge_currency_code,
            seller_authorization_note: charge_note,
            transaction_timeout: 0,
            capture_now: true,
            soft_descriptor: soft_descriptor,
            merchant_id: merchant_id,
            mws_auth_token: mws_auth_token
          )
        end
      end
      return response
    end

    def call_billing_agreement_api(
          amazon_reference_id,
          authorization_reference_id,
          charge_amount,
          charge_currency_code,
          charge_note,
          charge_order_id,
          store_name,
          custom_information,
          soft_descriptor,
          platform_id,
          merchant_id,
          mws_auth_token
    )

      response = get_billing_agreement_details(
        amazon_reference_id,
        merchant_id: merchant_id,
        mws_auth_token: mws_auth_token
      )
      if response.get_element('GetBillingAgreementDetailsResponse/GetBillingAgreementDetailsResult/BillingAgreementDetails/BillingAgreementStatus', 'State').eql?('Draft')
        response = set_billing_agreement_details(
          amazon_reference_id,
          platform_id: platform_id,
          seller_note: charge_note,
          seller_billing_agreement_id: charge_order_id,
          store_name: store_name,
          custom_information: custom_information,
          merchant_id: merchant_id,
          mws_auth_token: mws_auth_token
        )
        if response.success
          response = confirm_billing_agreement(
            amazon_reference_id,
            merchant_id: merchant_id,
            mws_auth_token: mws_auth_token
          )
          return response if response.success.eql?(false)
        end
      end

      response = authorize_on_billing_agreement(
        amazon_reference_id,
        authorization_reference_id,
        charge_amount,
        currency_code: charge_currency_code,
        seller_authorization_note: charge_note,
        transaction_timeout: 0,
        capture_now: true,
        soft_descriptor: soft_descriptor,
        seller_note: charge_note,
        platform_id: platform_id,
        seller_order_id: charge_order_id,
        store_name: store_name,
        custom_information: custom_information,
        inherit_shipping_address: true,
        merchant_id: merchant_id,
        mws_auth_token: mws_auth_token
      )
      return response
    end

    def is_order_reference?(amazon_reference_id)
      amazon_reference_id.start_with?('S', 'P')
    end

    def is_billing_agreement?(amazon_reference_id)
      amazon_reference_id.start_with?('C', 'B')
    end
  end
end
