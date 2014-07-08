# encoding: UTF-8
require 'api/spec_helper'
require 'nokogiri'
require 'yaml'

API_SPEC_INITIALIZER = File.expand_path("../initializer.rb", __FILE__)

unless File.exist?(API_SPEC_INITIALIZER)
  puts "[!] To run the functional tests you'll need to create `spec/functional/initializer.rb' and configure with your test account settings. See `spec/functional/initializer.rb.sample'."
else
  describe Adyen::API, "with an actual remote connection" do
    context "regular authorise call" do
      before :all do
        require API_SPEC_INITIALIZER
        Net::HTTP.stubbing_enabled = false
        @order_id = @user_id = Time.now.to_i
        perform_payment_request
      end

      after :all do
        Net::HTTP.stubbing_enabled = true
      end

      def perform_payment_request
        @payment_response = Adyen::API.authorise_payment(
          @order_id,
          { :currency => 'EUR', :value => '1234' },
          { :email => "#{@user_id}@example.com", :reference => @user_id },
          { :expiry_month => 06, :expiry_year => 2016, :holder_name => "Simon #{@user_id} Hopper", :number => '4444333322221111', :cvc => '737' },
          true
        )
      end

      # TODO disabled for now: https://github.com/wvanbergen/adyen/issues/29
      # it "performs a payment request" do
      #   @payment_response.should be_authorized
      #   @payment_response.psp_reference.should_not be_empty
      # end

      # TODO disabled for now: https://github.com/wvanbergen/adyen/issues/29
      # it "performs a recurring payment request" do
      #   response = Adyen::API.authorise_recurring_payment(
      #     @order_id,
      #     { :currency => 'EUR', :value => '1234' },
      #     { :email => "#{@user_id}@example.com", :reference => @user_id }
      #   )
      #   response.should be_authorized
      #   response.psp_reference.should_not be_empty
      # end

      # TODO disabled for now: https://github.com/wvanbergen/adyen/issues/29
      # it "performs a one-click payment request" do
      #   detail   = Adyen::API.list_recurring_details(@user_id).references.last
      #   response = Adyen::API.authorise_one_click_payment(
      #     @order_id,
      #     { :currency => 'EUR', :value => '1234' },
      #     { :email => "#{@user_id}@example.com", :reference => @user_id },
      #     '737',
      #     detail
      #   )
      #   response.should be_authorized
      #   response.psp_reference.should_not be_empty
      # end

      # TODO disabled for now: https://github.com/wvanbergen/adyen/issues/29
      #it "stores the provided ELV account details" do
        #response = Adyen::API.store_recurring_token(
          #{ :email => "#{@user_id}@example.com", :reference => @user_id },
          #{ :bank_location => "Berlin", :bank_name => "TestBank", :bank_location_id => "12345678", :holder_name => "Simon #{@user_id} Hopper", :number => "1234567890" }
        #)
        #response.should be_stored
        #response.recurring_detail_reference.should_not be_empty
      #end
      #it "stores the provided creditcard details" do
        #response = Adyen::API.store_recurring_token(
          #{ :email => "#{@user_id}@example.com", :reference => @user_id },
          #{ :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon #{@user_id} Hopper", :number => '4111111111111111' }
        #)
        #response.should be_stored
        #response.recurring_detail_reference.should_not be_empty
      #end

      it "captures a payment" do
        response = Adyen::API.capture_payment(@payment_response.psp_reference, { :currency => 'EUR', :value => '1234' })
        response.should be_success
      end

      it "refunds a payment" do
        response = Adyen::API.refund_payment(@payment_response.psp_reference, { :currency => 'EUR', :value => '1234' })
        response.should be_success
      end

      it "cancels or refunds a payment" do
        response = Adyen::API.cancel_or_refund_payment(@payment_response.psp_reference)
        response.should be_success
      end

      it "cancels a payment" do
        response = Adyen::API.cancel_payment(@payment_response.psp_reference)
        response.should be_success
      end

      # TODO disabled for now: https://github.com/wvanbergen/adyen/issues/29
      # it "disables a recurring contract" do
      #   response = Adyen::API.disable_recurring_contract(@user_id)
      #   response.should be_success
      #   response.should be_disabled
      # end
    end

    context "enabling 3-D Secure checks" do
      before :all do
        require API_SPEC_INITIALIZER
        Net::HTTP.stubbing_enabled = false
      end

      after :all do
        Net::HTTP.stubbing_enabled = true
      end

      let(:reference_id) { Time.now.to_i }
      let(:options) { true }
      let(:card_number) { '4444333322221111' }

      let(:payment_response) do
        Adyen::API.authorise_payment(
          reference_id,
          { :currency => 'EUR', :value => '1234' },
          { :email => "#{reference_id}@example.com", :reference => reference_id },
          { :expiry_month => 06, :expiry_year => 2016, :holder_name => "Simon #{reference_id} Hopper", :number => card_number, :cvc => '737' },
          options
        )
      end

      let(:browser_info) do
        {
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:29.0) Gecko/20100101 Firefox/29.0",
          accept_header: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        }
      end

      let(:options) do
        { recurring: true, browser_info: browser_info }
      end

      it "authorises successfully" do
        payment_response.should be_success
      end

      # Once you authorise a 3-D enrolled card Adyen will respond with a url.
      # You will have to redirect the customer to that url so that aonther
      # authentication process occurs outsite of your application.
      #
      # After the customer authenticates again on the card issuer he will be
      # redirected back to your store via a POST. Through that resquest you can
      # grab the MD and PaResponse values that should be used for the authorise3d
      # call. For local development and testing purposes you can use a service like
      # https://putsreq.herokuapp.com/ that allows you to record that POST request
      # copy the MD and PaResponse values and test them locally.
      context "authorise with 3-D enrolled credit card" do
        let(:card_number) { '4212345678901237' }

        it "authorises successfully" do
          payment_response.should be_enrolled_3d
        end
      end

      context "authorises 3-D payment" do
        it "authorises with payment 3d request" do
          if defined?(ENROLLED_3D_MD) && defined?(ENROLLED_3D_PA_RESPONSE)
            response = Adyen::API.authorise3d_payment(ENROLLED_3D_MD, ENROLLED_3D_PA_RESPONSE, "127.0.0.1", browser_info)
            expect(payment_response).to be_a_success
          else
            puts "[!] To run a API#authorise3d_payment call you'll need to set ENROLLED_3D_MD, ENROLLED_3D_PA_RESPONSE constants on your initializer.rb file."
          end
        end
      end
    end
  end
end
