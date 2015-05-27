# encoding: UTF-8

require 'rspec'
require 'adyen'
require 'adyen/matchers'
require 'webmock/rspec'

WebMock.allow_net_connect!

RSpec.configure do |config|
  config.include Adyen::Matchers
end
