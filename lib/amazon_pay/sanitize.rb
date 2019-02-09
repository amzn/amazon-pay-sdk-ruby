# rubocop:disable Metrics/MethodLength, Metrics/LineLength

module AmazonPay
  # Removes PII and other sensitive data for the logger
  class Sanitize
    def initialize(input_data)
      @copy = input_data ? input_data.dup : ''
    end

    def sanitize_request_data
      # Array of item to remove

      patterns = %w[
        Buyer
        PhysicalDestination
        BillingAddress
        AuthorizationBillingAddress
        SellerNote
        SellerAuthorizationNote
        SellerCaptureNote
        SellerRefundNote
      ]

      patterns.each do |s|
        @copy.gsub!(/([?|&]#{s}=)[^\&]+/ms, s + '=*REMOVED*')
      end

      @copy
    end

    def sanitize_response_data
      # Array of item to remove

      patterns = []
      patterns.push(%r{(?<=<Buyer>).*(?=<\/Buyer>)}s)
      patterns.push(%r{(?<=<PhysicalDestination>).*(?=<\/PhysicalDestination>)}ms)
      patterns.push(%r{(?<=<BillingAddress>).*(?=<\/BillingAddress>)}s)
      patterns.push(%r{(?<=<SellerNote>).*(?=<\/SellerNote>)}s)
      patterns.push(%r{(?<=<AuthorizationBillingAddress>).*(?=<\/AuthorizationBillingAddress>)}s)
      patterns.push(%r{(?<=<SellerAuthorizationNote>).*(?=<\/SellerAuthorizationNote>)}s)
      patterns.push(%r{(?<=<SellerCaptureNote>).*(?=<\/SellerCaptureNote>)}s)
      patterns.push(%r{(?<=<SellerRefundNote>).*(?=<\/SellerRefundNote>)}s)

      patterns.each do |s|
        @copy.gsub!(s, '*REMOVED*')
      end

      @copy
    end
  end
end
