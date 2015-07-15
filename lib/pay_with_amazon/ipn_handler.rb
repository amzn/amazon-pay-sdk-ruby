require 'base64'
require 'json'
require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'

module PayWithAmazon

  class IpnWasNotAuthenticError < StandardError
  end

  # Pay with Amazon Ipn Handler
  #
  # This class authenticates an sns message sent from Amazon. It
  # will validate the header, subject, and certificate. After validation
  # there are many helper methods in place to extract information received
  # from the ipn notification.
  class IpnHandler

    SIGNABLE_KEYS = [
      'Message',
      'MessageId',
      'Timestamp',
      'TopicArn',
      'Type',
    ].freeze

    COMMON_NAME = 'sns.amazonaws.com'

    attr_reader(:headers, :body)
    attr_accessor(:proxy_addr, :proxy_port, :proxy_user, :proxy_pass)

    # @param headers [request.headers]
    # @param body [request.body.read]
    # @optional proxy_addr [String]
    # @optional proxy_port [String]
    # @optional proxy_user [String]
    # @optional proxy_pass [String]
    def initialize(
            headers,
            body,
            option = {})
      @body = body
      @raw = parse_from(@body)
      @headers = headers
      @proxy_addr = options.fetch(:proxy_addr){ :ENV }
      @proxy_port = options.fetch(:proxy_port){ nil }
      @proxy_user = options.fetch(:proxy_user){ nil }
      @proxy_pass = options.fetch(:proxy_pass){ nil }
    end

    # This method will authenticate the ipn message sent from Amazon.
    # It will return true if everything is verified. It will raise an
    # error message if verification fails.
    def authentic?
      begin
        decoded_from_base64 = Base64.decode64(signature)
        validate_header
        validate_subject(get_certificate.subject)
        public_key = get_public_key_from(get_certificate)
        verify_public_key(public_key, decoded_from_base64, canonical_string)

        return true
      rescue IpnWasNotAuthenticError => e
        raise e.message
      end
    end

    def type
      @raw['Type']
    end

    def message_id
      @raw['MessageId']
    end

    def topic_arn
      @raw['TopicArn']
    end

    def message
      @raw['Message']
    end

    def timestamp
      @raw['Timestamp']
    end

    def signature
      @raw['Signature']
    end

    def signature_version
      @raw['SignatureVersion']
    end

    def signing_cert_url
      @raw['SigningCertURL']
    end

    def unsubscribe_url
      @raw['UnsubscribeURL']
    end

    def notification_type
      parse_from(@raw['Message'])["NotificationType"]
    end

    def seller_id
      parse_from(@raw['Message'])["SellerId"]
    end

    def environment
      parse_from(@raw['Message'])["ReleaseEnvironment"]
    end

    def version
      parse_from(@raw['Message'])["Version"]
    end

    def notification_data
      parse_from(@raw['Message'])["NotificationData"]
    end

    def message_timestamp
      parse_from(@raw['Message'])["Timestamp"]
    end

    def parse_from(json)
      JSON.parse(json)
    end

    protected

    def get_certificate
      cert_pem = download_cert(signing_cert_url)
      OpenSSL::X509::Certificate.new(cert_pem)
    end

    def get_public_key_from(certificate)
      OpenSSL::PKey::RSA.new(certificate.public_key)
    end

    def canonical_string
      text = ''
      SIGNABLE_KEYS.each do |key|
        value = @raw[key]
        next if value.nil? or value.empty?
        text << key << "\n"
        text << value << "\n"
      end
      text
    end

    def download_cert(url)
      uri = URI.parse(url)
      unless
        uri.scheme == 'https' &&
        uri.host.match(/^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$/) &&
        File.extname(uri.path) == '.pem'
      then
        msg = "Error - certificate is not hosted at AWS URL (https): #{url}"
        raise IpnWasNotAuthenticError, msg
      end
      tries = 0
      begin
        resp = https_get(url)
        resp.body
      rescue => error
        tries += 1
        retry if tries < 3
        raise error
      end
    end

    def https_get(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port, @proxy_addr, @proxy_port, @proxy_user, @proxy_pass)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.start
      resp = http.request(Net::HTTP::Get.new(uri.request_uri))
      http.finish
      resp
    end

    def validate_header
      unless
        @headers['x-amz-sns-message-type'] == 'Notification'
      then
        msg = "Error - Header does not contain x-amz-sns-message-type header"
        raise IpnWasNotAuthenticError, msg
      end
    end

    def validate_subject(certificate_subject)
      subject = certificate_subject.to_a
      unless
        subject[4][1] == COMMON_NAME
      then
        msg = "Error - Unable to verify certificate subject issued by Amazon"
        raise IpnWasNotAuthenticError, msg
      end
    end

    def verify_public_key(public_key, decoded_signature, signed_string)
      unless
        public_key.verify(OpenSSL::Digest::SHA1.new, decoded_signature, signed_string)
      then
        msg = "Error - Unable to verify public key with signature and signed string"
        raise IpnWasNotAuthenticError, msg
      end
    end

  end

end
