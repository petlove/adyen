# encoding: UTF-8

require 'date'
require 'spec_helper'
require 'adyen/form'

describe Adyen::Form do

  describe 'hidden fields generation' do
    include APISpecHelper
    subject { %Q'<form action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">#{Adyen::Form.hidden_fields(@attributes)}</form>' }

    before(:each) do
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
        :merchant_reference => 'Internet Order 12345', :skin => :testing,
        :session_validity => Time.now + 3600 }
    end

    for_each_xml_backend do
      it { should have_adyen_payment_form }
    end

    it { should include('<input type="hidden" name="merchantAccount" value="TestMerchant" />') }

    context "width default_form_params" do
      before(:each) do
        Adyen.configuration.register_form_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)', {
          :merchant_account => 'OtherMerchant',
        })
      end

      it { should include('<input type="hidden" name="merchantAccount" value="OtherMerchant" />') }
      it { should_not include('<input type="hidden" name="merchantAccount" value="TestMerchant" />') }
    end
  end

  describe 'signature calculation' do

    # This example is taken from the Adyen integration manual

    before(:each) do

      @parameters = { :currency_code => 'GBP', :payment_amount => 10000,
        :ship_before_date => '2007-10-20', :merchant_reference => 'Internet Order 12345',
        :skin => :testing, :session_validity => '2007-10-11T11:00:00Z',
        :billing_address => {
           :street               => 'Alexanderplatz',
           :house_number_or_name => '0815',
           :city                 => 'Berlin',
           :postal_code          => '10119',
           :state_or_province    => 'Berlin',
           :country              => 'Germany',
          }
        }

      Adyen::Form.do_parameter_transformations!(@parameters)
    end

    it "should construct the signature base string correctly" do
      signature_string = Adyen::Form.calculate_signature_string(@parameters)
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z"

      signature_string = Adyen::Form.calculate_signature_string(@parameters.merge(:merchant_return_data => 'testing123'))
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Ztesting123"

    end

    it "should calculate the signature correctly" do
      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should == 'x58ZcRVL1H6y+XSeBGrySJ9ACVo='
    end

    it "should raise ArgumentError on empty shared_secret" do
      expect do
        @parameters.delete(:shared_secret)
        signature = Adyen::Form.calculate_signature(@parameters)
      end.to raise_error ArgumentError
    end

    it "should calculate the signature base string correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @parameters.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')

      signature_string = Adyen::Form.calculate_signature_string(@parameters)
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Zgras.shopper@somewhere.orggrasshopper52DEFAULT"
    end

    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @parameters.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')

      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should == 'F2BQEYbE+EUhiRGuPtcD16Gm7JY='
    end

    context 'billing address' do

      it "should construct the signature base string correctly" do
        signature_string = Adyen::Form.calculate_billing_address_signature_string(@parameters[:billing_address])
        signature_string.should == "Alexanderplatz0815Berlin10119BerlinGermany"
      end

      it "should calculate the signature correctly" do
        signature = Adyen::Form.calculate_billing_address_signature(@parameters)
        signature.should == '5KQb7VJq4cz75cqp11JDajntCY4='
      end

      it "should raise ArgumentError on empty shared_secret" do
        expect do
          @parameters.delete(:shared_secret)
          signature = Adyen::Form.calculate_billing_address_signature(@parameters)
        end.to raise_error ArgumentError
      end
    end

  end
end
