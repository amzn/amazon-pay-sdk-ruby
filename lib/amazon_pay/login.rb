# rubocop:disable Metrics/MethodLength, Metrics/LineLength, Metrics/AbcSize

require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'openssl'

module AmazonPay
  # AmazonPay API
  #
  # This class allows you to obtain user profile
  # information once a user has logged into your
  # application using their Amazon credentials.
  class Login
    attr_reader(:region)

    attr_accessor(:client_id, :sandbox)

    # @param client_id [String]
    # @optional region [Symbol] Default: :na
    # @optional sandbox [Boolean] Default: false
    def initialize(client_id, region: :na, sandbox: false)
      @client_id = client_id
      @region = region
      @endpoint = region_hash[@region]
      @sandbox = sandbox
      @sandbox_str = @sandbox ? 'api.sandbox' : 'api'
    end

    # This method will validate the access token and
    # return the user's profile information.
    # @param access_token [String]
    def get_login_profile(access_token)
      decoded_access_token = CGI.unescape(access_token)
      uri = URI("https://#{@sandbox_str}.#{@endpoint}/auth/o2/tokeninfo")
      req = Net::HTTP::Get.new(uri.request_uri)
      req['x-amz-access-token'] = decoded_access_token
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      response = http.request(req)
      decode = JSON.parse(response.body)

      raise 'Invalid Access Token' if decode['aud'] != @client_id

      uri = URI.parse("https://#{@sandbox_str}.#{@endpoint}/user/profile")
      req = Net::HTTP::Get.new(uri.request_uri)
      req['x-amz-access-token'] = decoded_access_token
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      response = http.request(req)
      decoded_login_profile = JSON.parse(response.body)
      decoded_login_profile
    end

    private

    def region_hash
      {
        jp: 'amazon.co.jp',
        uk: 'amazon.co.uk',
        de: 'amazon.de',
        eu: 'amazon.co.uk',
        us: 'amazon.com',
        na: 'amazon.com'
      }
    end
  end
end
