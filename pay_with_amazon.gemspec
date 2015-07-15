##
# Login and Pay with Amazon Ruby SDK
#
# @category Amazon
# @package Amazon_Payments
# @copyright Copyright (c) 2015 Amazon.com
# @license http://opensource.org/licenses/Apache-2.0 Apache License, Version 2.0
#
##
# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
require 'pay_with_amazon/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'pay_with_amazon'
  s.version = PayWithAmazon::VERSION
  s.summary = 'Amazon Payments - Login and Pay with Amazon Ruby SDK'
  s.description = 'Amazon Payments - Login and Pay with Amazon Ruby SDK'
  s.required_ruby_version = '>= 1.9.3'
  s.author = 'Amazon Payments'
  s.email = 'pay-with-amazon-sdk@amazon.com'
  s.homepage = 'https://github.com/amzn/login-and-pay-with-amazon-sdk-ruby'
  s.files = Dir.glob('lib/**/*') + %w(LICENSE NOTICE README.md)
  s.require_path = ['lib']
  s.license = 'Apache License, Version 2.0'
end
