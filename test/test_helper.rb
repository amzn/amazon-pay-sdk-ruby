require 'simplecov'
SimpleCov.start

require 'webmock'
include WebMock::API
WebMock.enable!

require "test/unit/assertions"
include Test::Unit::Assertions

require 'openssl'

require 'amazon_pay'

require 'minitest/autorun'

