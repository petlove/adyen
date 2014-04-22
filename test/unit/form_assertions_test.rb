# encoding: UTF-8
require 'test_helper'
require 'adyen/form_assertions'

class FormAssertionsTest < Minitest::Test
  include Adyen::FormAssertions

  def each_xpath_backend
    backends = [Adyen::API::XMLQuerier::REXMLBackend, Adyen::API::XMLQuerier::NokogiriBackend]
    backends.each do |backend|
      Adyen::API::XMLQuerier.stubs(:default_backend).returns(backend.new)
      yield
    end
  end

  def setup
    @html = <<-HTML
      <html>
        <body>
          <form action="https://test.adyen.com/hpp/select.shtml" method="post">
            <input type="hidden" name="merchantAccount" value="TestMerchant" />
            <input type="hidden" name="currencyCode" value="GBP" />
            <input type="hidden" name="paymentAmount" value="10000" />
            <input type="hidden" name="shipBeforeDate" value="2014-03-28" />
            <input type="hidden" name="merchantReference" value="Internet Order 12345" />
            <input type="hidden" name="sessionValidity" value="2014-03-28T09:17:18Z" />
            <input type="hidden" name="skinCode" value="4aD37dJA" />
            <input type="hidden" name="merchantSig" value="Og8DAaHoh8HhLpSbDEgxGKu4go8=" />
          </form>
        </body>
      </html>
    HTML
  end

  def test_payment_form_assertions
    each_xpath_backend do
      assert_adyen_payment_form @html
      assert_adyen_payment_form @html, currency_code: 'GBP', payment_amount: 200
    end
  end
end
