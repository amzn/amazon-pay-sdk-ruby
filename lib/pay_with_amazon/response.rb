require 'rexml/document'

module PayWithAmazon

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
       xml = self.to_xml
       xml.elements.each(xpath) do |element|
         @value = element.elements[xml_element].text
       end
       return @value
     end

     def code
       @response.code
     end

     def success
      if @response.code.eql? '200'
         return true
      else
         return false
      end
     end

  end

end
