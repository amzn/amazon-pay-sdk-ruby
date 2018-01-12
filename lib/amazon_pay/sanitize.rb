module AmazonPay
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
      patterns.push(/(?<=<Buyer>).*(?=<\/Buyer>)/s)
      patterns.push(/(?<=<PhysicalDestination>).*(?=<\/PhysicalDestination>)/ms)
      patterns.push(/(?<=<BillingAddress>).*(?=<\/BillingAddress>)/s)
      patterns.push(/(?<=<SellerNote>).*(?=<\/SellerNote>)/s)
      patterns.push(/(?<=<AuthorizationBillingAddress>).*(?=<\/AuthorizationBillingAddress>)/s)
      patterns.push(/(?<=<SellerAuthorizationNote>).*(?=<\/SellerAuthorizationNote>)/s)
      patterns.push(/(?<=<SellerCaptureNote>).*(?=<\/SellerCaptureNote>)/s)
      patterns.push(/(?<=<SellerRefundNote>).*(?=<\/SellerRefundNote>)/s)

      patterns.each do |s|
        @copy.gsub!(s, '*REMOVED*')
      end

      @copy
    end
  end
end
