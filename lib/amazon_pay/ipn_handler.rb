# rubocop:disable Metrics/MethodLength, Metrics/ClassLength, Metrics/LineLength, Metrics/ParameterLists, Metrics/AbcSize, Metrics/CyclomaticComplexity, Rails/Blank

require 'base64'
require 'json'
require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'logger'
require 'stringio'

module AmazonPay
  class IpnWasNotAuthenticError < StandardError
  end

  # AmazonPay Ipn Handler
  #
  # This class authenticates an sns message sent from Amazon. It
  # will validate the header, subject, and certificate. After validation
  # there are many helper methods in place to extract information received
  # from the ipn notification.
  class IpnHandler
    MSG_HEADER = 'Error - Header does not contain x-amz-sns-message-type header'.freeze
    MSG_CERTIFICATE = 'Error - Unable to verify certificate subject issued by Amazon'.freeze
    MSG_KEY = 'Error - Unable to verify public key with signature and signed string'.freeze

    SIGNABLE_KEYS = %w[
      Message
      MessageId
      Timestamp
      TopicArn
      Type
    ].freeze

    COMMON_NAME = 'sns.amazonaws.com'.freeze

    attr_reader(
      :headers,
      :body
    )
    attr_accessor(
      :proxy_addr,
      :proxy_port,
      :proxy_user,
      :proxy_pass
    )

    # @param headers [request.headers]
    # @param body [request.body.read]
    # @optional proxy_addr [String]
    # @optional proxy_port [String]
    # @optional proxy_user [String]
    # @optional proxy_pass [String]
    def initialize(
      headers,
      body,
      proxy_addr: :ENV,
      proxy_port: nil,
      proxy_user: nil,
      proxy_pass: nil,
      log_enabled: false,
      log_file_name: nil,
      log_level: :DEBUG
    )

      @body = body
      @raw = parse_from(@body)
      @headers = headers
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      @proxy_user = proxy_user
      @proxy_pass = proxy_pass

      @log_enabled = log_enabled
      @logger = AmazonPay::LogInitializer.new(log_file_name, log_level).create_logger if @log_enabled
    end

    # This method will authenticate the ipn message sent from Amazon.
    # It will return true if everything is verified. It will raise an
    # error message if verification fails.
    def authentic?
      decoded_from_base64 = Base64.decode64(signature)
      validate_header
      validate_subject(certificate.subject)
      public_key = public_key_from(certificate)
      verify_public_key(public_key, decoded_from_base64, canonical_string)

      return true
    rescue IpnWasNotAuthenticError => e
      raise e.message
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
      parse_from(@raw['Message'])['NotificationType']
    end

    def seller_id
      parse_from(@raw['Message'])['SellerId']
    end

    def environment
      parse_from(@raw['Message'])['ReleaseEnvironment']
    end

    def version
      parse_from(@raw['Message'])['Version']
    end

    def notification_data
      parse_from(@raw['Message'])['NotificationData']
    end

    def message_timestamp
      parse_from(@raw['Message'])['Timestamp']
    end

    def parse_from(json)
      JSON.parse(json)
    end

    protected

    def certificate
      cert_pem = download_cert(signing_cert_url)
      OpenSSL::X509::Certificate.new(cert_pem)
    end

    def public_key_from(certificate)
      OpenSSL::PKey::RSA.new(certificate.public_key)
    end

    def canonical_string
      text = ''
      SIGNABLE_KEYS.each do |key|
        value = @raw[key]
        next if value.nil? || value.empty?
        text << key << "\n"
        text << value << "\n"
      end
      text
    end

    def download_cert(url)
      uri = URI.parse(url)
      unless uri.scheme == 'https' &&
             uri.host.match(/^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$/) &&
             File.extname(uri.path) == '.pem'
        msg = "Error - certificate is not hosted at AWS URL (https): #{url}"
        raise IpnWasNotAuthenticError, msg
      end
      tries = 0
      begin
        resp = https_get(url)
        if @log_enabled
          data = AmazonPay::Sanitize.new(resp.body)
          @logger.debug(data.sanitize_response_data)
        end
        resp.body
      rescue StandardError => error
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
      raise IpnWasNotAuthenticError, MSG_HEADER unless @headers['x-amz-sns-message-type'] == 'Notification'
    end

    def validate_subject(certificate_subject)
      subject = certificate_subject.to_a
      raise IpnWasNotAuthenticError, MSG_CERTIFICATE unless subject.rassoc(COMMON_NAME)
    end

    def verify_public_key(public_key, decoded_signature, signed_string)
      raise IpnWasNotAuthenticError, MSG_KEY unless public_key.verify(OpenSSL::Digest::SHA1.new, decoded_signature, signed_string)
    end
  end
end
