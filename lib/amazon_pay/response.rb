require 'rexml/document'

module AmazonPay
  # This class provides helpers to parse the response
  class Response
    def initialize(response)
      @response = response
    end

    def body
      @response.body
    end

    def to_xml
      REXML::Document.new(body)
    end

    def get_element(xpath, xml_element)
      xml = to_xml
      value = nil
      xml.elements.each(xpath) do |element|
        value = element.elements[xml_element].text
      end
      value
    end

    def code
      @response.code
    end

    def success
      @response.code.eql? '200'
    end
  end
end
