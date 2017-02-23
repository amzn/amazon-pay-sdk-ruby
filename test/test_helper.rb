require 'simplecov'
SimpleCov.start

require 'webmock'
include WebMock::API
WebMock.enable!

require 'amazon_pay'
require 'minitest/autorun'
