require 'uri'
require 'net/http'
require 'net/https'
require 'base64'
require 'openssl'

module AmazonPay

  # This class creates the request to send to the
  # specified MWS endpoint.
  class Request
        
    MAX_RETRIES = 3

    def initialize(
            parameters,
            optional,
            default_hash,
            mws_endpoint,
            sandbox_str,
            secret_key,
            proxy_addr,
            proxy_port,
            proxy_user,
            proxy_pass,
            throttle,
            application_name,
            application_version)

      @parameters = parameters
      @optional = optional
      @default_hash = default_hash
      @mws_endpoint = mws_endpoint
      @sandbox_str = sandbox_str
      @secret_key = secret_key
      @proxy_addr = proxy_addr
      @proxy_port = proxy_port
      @proxy_user = proxy_user
      @proxy_pass = proxy_pass
      @throttle = throttle
      @application_name = application_name
      @application_version = application_version
    end

    # This method sends the post request.
    def send_post
      post_url = build_post_url
      post(@mws_endpoint, @sandbox_str, post_url)
    end

    private

    # This method combines the required and optional
    # parameters to sign the post body and generate
    # the post url.
    def build_post_url
      @optional.map { |k, v| @parameters[k] = v unless v.nil? }
      @parameters = @default_hash.merge(@parameters)
      post_url = @parameters.sort.map { |k, v| "#{k}=#{ custom_escape(v) }" }.join("&")
      post_body = ["POST", "#{@mws_endpoint}", "/#{@sandbox_str}/#{AmazonPay::API_VERSION}", post_url].join("\n")
      post_url += "&Signature=" + sign(post_body)
      return post_url
    end

    # This method signs the post body that is being sent
    # using the secret key provided.
    def sign(post_body)
      custom_escape(Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, @secret_key, post_body)))
    end

    # This method performs the post to the MWS endpoint.
    # It will retry three times after the initial post if
    # the status code comes back as either 500 or 503.
    def post(mws_endpoint, sandbox_str, post_url)
      uri = URI("https://#{mws_endpoint}/#{sandbox_str}/#{AmazonPay::API_VERSION}")
      https = Net::HTTP.new(uri.host, uri.port, @proxy_addr, @proxy_port, @proxy_user, @proxy_pass)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      
      user_agent = {"User-Agent" => "#{AmazonPay::SDK_NAME}/#{AmazonPay::VERSION}; (#{@application_name + '/' if @application_name }#{@application_version.to_s + ';' if @application_version} #{RUBY_VERSION}; #{RUBY_PLATFORM})"}

      tries = 0
      begin
        response = https.post(uri.path, post_url, user_agent)
        if @throttle.eql?(true)
          if response.code.eql?('500')
            raise 'InternalServerError'
          elsif response.code.eql?('503')
            raise 'ServiceUnavailable or RequestThrottled'
          end
        end
        AmazonPay::Response.new(response)
      rescue => error
        tries += 1
        sleep(get_seconds_for_try_count(tries))
        retry if tries <= MAX_RETRIES
        raise error.message
      end
    end

    def get_seconds_for_try_count(try_count)
      seconds = { 1=>1, 2=>4, 3=>10, 4=>0 }
      seconds[try_count]
    end

    def custom_escape(val)
      val.to_s.gsub(/([^\w.~-]+)/) do
        "%" + $1.unpack("H2" * $1.bytesize).join("%").upcase
      end
    end

  end

end
