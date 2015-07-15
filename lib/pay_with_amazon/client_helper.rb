module PayWithAmazon

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
            options = {})
      charge_currency_code =  options.fetch(:charge_currency_code){ @currency_code }
      charge_note          =  options.fetch(charge_note){ nil }
      charge_order_id      =  options.fetch(:charge_order_id){ nil }
      store_name           =  options.fetch(:store_name){ nil }
      custom_information   =  options.fetch(:custom_information){ nil }
      soft_descriptor      =  options.fetch(:soft_descriptor){ nil }
      platform_id          =  options.fetch(:platform_id){ nil }
      merchant_id          =  options.fetch(:merchant_id){ @merchant_id }
      mws_auth_token       =  options.fetch(:mws_auth_token){ nil }

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
                       mws_auth_token)
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
                       mws_auth_token)
        return response
      end
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
            mws_auth_token)

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
        mws_auth_token: mws_auth_token)
      if response.success
        response = confirm_order_reference(
          amazon_reference_id,
          merchant_id: merchant_id,
          mws_auth_token: mws_auth_token)
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
            mws_auth_token: mws_auth_token)
          return response
        else
          return response
        end
      else
        return response
      end
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
            mws_auth_token)

      response = get_billing_agreement_details(
        amazon_reference_id,
        merchant_id: merchant_id,
        mws_auth_token: mws_auth_token)
      if response.get_element('GetBillingAgreementDetailsResponse/GetBillingAgreementDetailsResult/BillingAgreementDetails/BillingAgreementStatus','State').eql?('Draft')
        response = set_billing_agreement_details(
          amazon_reference_id,
          platform_id: platform_id,
          seller_note: charge_note,
          seller_billing_agreement_id: charge_order_id,
          store_name: store_name,
          custom_information: custom_information,
          merchant_id: merchant_id,
          mws_auth_token: mws_auth_token)
        if response.success
          response = confirm_billing_agreement(
            amazon_reference_id,
            merchant_id: merchant_id,
            mws_auth_token: mws_auth_token)
          if response.success.eql?(false)
            return response
          end
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
        mws_auth_token: mws_auth_token)
      return response
    end


    def is_order_reference?(amazon_reference_id)
      amazon_reference_id.start_with?('S','P')
    end

    def is_billing_agreement?(amazon_reference_id)
      amazon_reference_id.start_with?('C','B')
    end

  end

end
