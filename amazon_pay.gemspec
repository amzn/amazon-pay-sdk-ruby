##
# AmazonPay Ruby SDK
#
# @category Amazon
# @package AmazonPay
# @copyright Copyright (c) 2017 Amazon.com
# @license http://opensource.org/licenses/Apache-2.0 Apache License, Version 2.0
#
##
# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
require 'amazon_pay/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'amazon_pay'
  s.version = AmazonPay::VERSION
  s.summary = 'AmazonPay Ruby SDK'
  s.description = 'AmazonPay Ruby SDK'
  s.required_ruby_version = '>= 2.0.0'
  s.author = 'AmazonPay'
  s.email = 'amazon-pay-sdk@amazon.com'
  s.homepage = 'https://github.com/amzn/amazon-pay-sdk-ruby'
  s.files = Dir.glob('lib/**/*') + %w(LICENSE NOTICE README.md)
  s.require_path = ['lib']
  s.license = 'Apache License, Version 2.0'

  s.add_runtime_dependency 'rexml'
end
