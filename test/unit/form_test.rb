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

  # it "should calculate the signature string correctly" do
  #   Adyen::Form.redirect_signature_string(@params).should == 'AUTHORISED1211992213193029Internet Order 123454aD37dJA'
  #   params = @params.merge(:merchantReturnData => 'testing1234')
  #   Adyen::Form.redirect_signature_string(params).should == 'AUTHORISED1211992213193029Internet Order 123454aD37dJAtesting1234'
  # end

  # it "should calculate the signature correctly" do
  #   Adyen::Form.redirect_signature(@params).should == @params[:merchantSig]
  # end

  # it "should check the signature correctly with explicit shared signature" do
  #   Adyen::Form.redirect_signature_check(@params, 'Kah942*$7sdp0)').should be_true
  # end

  # it "should check the signature correctly using the stored shared secret" do
  #   Adyen::Form.redirect_signature_check(@params).should be_true
  # end


  def test_raises_on_missing_required_data
    @params.delete(:skinCode)
    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check({}) }
    assert_raises(ArgumentError) { Adyen::Form.redirect_signature_check(@params) }
  end

  def test_redirect_signature_check
    assert Adyen::Form.redirect_signature_check(@params)
    assert !Adyen::Form.redirect_signature_check(@params.merge(:pspReference => 'tampered'))
    assert !Adyen::Form.redirect_signature_check(@params.merge(:merchantSig => 'tampered'))
  end
end
