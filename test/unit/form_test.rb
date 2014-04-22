# encoding: UTF-8
require 'test_helper'

class FormTest < Minitest::Test
  def setup
    Adyen.stubs(:configuration).returns(Adyen::Configuration.new)
    Adyen.configuration.register_form_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)')
    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'

    @params = { :authResult => 'AUTHORISED', :pspReference => '1211992213193029',
        :merchantReference => 'Internet Order 12345', :skinCode => '4aD37dJA',
        :merchantSig => 'ytt3QxWoEhAskUzUne0P5VA9lPw='}

    @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
      :merchant_reference => 'Internet Order 12345', :skin => :testing,
      :session_validity => Time.now + 3600 }    
  end

  def test_default_form_action_url
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url(:test)
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::Form.url(:live)
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url
  end

  def test_form_action_url_based_on_environment
    Adyen.configuration.stubs(:autodetect_environment).returns('live')
    assert_equal 'https://live.adyen.com/hpp/select.shtml', Adyen::Form.url

    Adyen.configuration.environment = :test
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url
  end

  def test_form_action_with_payment_flow
    Adyen.configuration.payment_flow = :select
    assert_equal 'https://test.adyen.com/hpp/select.shtml', Adyen::Form.url

    Adyen.configuration.payment_flow = :pay
    assert_equal 'https://test.adyen.com/hpp/pay.shtml', Adyen::Form.url

    Adyen.configuration.payment_flow = :details
    assert_equal 'https://test.adyen.com/hpp/details.shtml', Adyen::Form.url
  end

  def test_custom_checkout_domain
    Adyen.configuration.payment_flow = :select
    Adyen.configuration.payment_flow_domain = "checkout.mydomain.com"
    assert_equal 'https://checkout.mydomain.com/hpp/select.shtml', Adyen::Form.url
  end

  def test_redirect_signature
    signature_base = Adyen::Form.redirect_signature_string(@params)
    assert_equal 'AUTHORISED1211992213193029Internet Order 123454aD37dJA', signature_base

    signature_base_with_return_data = Adyen::Form.redirect_signature_string(@params.merge(:merchantReturnData => 'testing1234'))
    assert_equal 'AUTHORISED1211992213193029Internet Order 123454aD37dJAtesting1234', signature_base_with_return_data

    assert_equal @params[:merchantSig], Adyen::Form.redirect_signature(@params)
  end

  def test_raises_on_missing_required_data
    @params.delete(:skinCode)
    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check({}) }
    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check(@params) }
  end

  def test_redirect_signature_check
    assert Adyen::Form.redirect_signature_check(@params, 'Kah942*$7sdp0)')
    assert Adyen::Form.redirect_signature_check(@params)
    assert !Adyen::Form.redirect_signature_check(@params.merge(:pspReference => 'tampered'))
    assert !Adyen::Form.redirect_signature_check(@params.merge(:merchantSig => 'tampered'))
  end

  def test_redirect_url
    redirect_url = Adyen::Form.redirect_url(@attributes)
    assert redirect_url.start_with?(Adyen::Form.url)

    param_names = redirect_url.split('?', 2).last.split('&').map { |param| param.split('=', 2).first }
    assert @attributes.keys.all? { |k| param_names.include?(Adyen::Form.camelize(k)) }
    assert param_names.include?('merchantSig')
  end

  def test_flatten
    parameters = { :billing_address => { :street => 'My Street'} }
    assert_equal Hash.new, Adyen::Form.flatten(nil)
    assert_equal 'My Street', Adyen::Form.flatten(parameters)['billingAddress.street']
  end
end
