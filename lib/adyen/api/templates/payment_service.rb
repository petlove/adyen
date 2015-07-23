# encoding: utf-8
module Adyen
  module API
    class PaymentService < SimpleSOAPClient
      class << self
        private

        def modification_request(method, body = nil)
          return <<EOS
    <payment:#{method} xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:modificationRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:originalReference>%s</payment:originalReference>
        #{body}
      </payment:modificationRequest>
    </payment:#{method}>
EOS
        end

        def modification_request_with_amount(method)
          modification_request(method, <<EOS)
        <payment:modificationAmount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:modificationAmount>
EOS
        end
      end

      # @private
      CAPTURE_LAYOUT          = modification_request_with_amount(:capture)
      # @private
      REFUND_LAYOUT           = modification_request_with_amount(:refund)
      # @private
      CANCEL_LAYOUT           = modification_request(:cancel)
      # @private
      CANCEL_OR_REFUND_LAYOUT = modification_request(:cancelOrRefund)

      # @private
      LAYOUT = <<EOS
    <payment:authorise xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:paymentRequest>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:reference>%s</payment:reference>
%s
      </payment:paymentRequest>
    </payment:authorise>
EOS

      # @private
      BOLETO_LAYOUT = <<EOS
    <authorise xmlns="http://payment.services.adyen.com">
      <paymentRequest>
        <merchantAccount>%s</merchantAccount>
        <reference>%s</reference>
%s
      </paymentRequest>
    </authorise>
EOS

      # @private
      LAYOUT_3D = <<EOS
    <payment:authorise3d xmlns:payment="http://payment.services.adyen.com" xmlns:recurring="http://recurring.services.adyen.com" xmlns:common="http://common.services.adyen.com">
      <payment:paymentRequest3d>
        <payment:merchantAccount>%s</payment:merchantAccount>
        <payment:shopperIP>%s</payment:shopperIP>
%s
      </payment:paymentRequest3d>
    </payment:authorise3d>
EOS

      # @private
      AMOUNT_PARTIAL = <<EOS
        <payment:amount>
          <common:currency>%s</common:currency>
          <common:value>%s</common:value>
        </payment:amount>
EOS


      # @private
      AMOUNT_BOLETO_PARTIAL = <<EOS
        <amount>
          <ns1:currency xmlns:ns1="http://common.services.adyen.com">%s</ns1:currency>
          <ns2:value xmlns:ns2="http://common.services.adyen.com">%s</ns2:value>
        </amount>
EOS

      # @private
      BOLETO_PARTIAL = <<EOS
        <billingAddress>
          <ns3:city xmlns:ns3="http://common.services.adyen.com">%s</ns3:city>
          <ns4:country xmlns:ns4="http://common.services.adyen.com">BR</ns4:country>
          <ns5:houseNumberOrName xmlns:ns5="http://common.services.adyen.com">%s</ns5:houseNumberOrName>
          <ns6:postalCode xmlns:ns6="http://common.services.adyen.com">%s</ns6:postalCode>
          <ns7:stateOrProvince xmlns:ns7="http://common.services.adyen.com">%s</ns7:stateOrProvince>
          <ns8:street xmlns:ns8="http://common.services.adyen.com">%s</ns8:street>
        </billingAddress>
        <deliveryDate xmlns="http://payment.services.adyen.com">%s</deliveryDate>
        <selectedBrand xmlns="http://payment.services.adyen.com">boletobancario_bradesco</selectedBrand>
        <shopperName xmlns="http://payment.services.adyen.com">
          <ns9:firstName xmlns:ns9="http://common.services.adyen.com">%s</ns9:firstName>
          <ns10:lastName xmlns:ns10="http://common.services.adyen.com">%s</ns10:lastName>
        </shopperName>
        <shopperStatement>
            SR caixa: Não receber após o vencimento.

            Não poderemos garantir a disponibilidade dos produtos desse pedido para pagamentos
            fora do prazo (2 dias). O prazo de compensação é de 1 dia util e o prazo de entrega
            começa a ser contado a partir da compensação desse boleto, ou seja, adicione um dia
            util a mais a data inicial da entrega. Vencimentos no sábado ou domingo podem ser
            pagos na segunda feira.
        </shopperStatement>
        <socialSecurityNumber>%s</socialSecurityNumber>
EOS

      # @private
      CARD_PARTIAL = <<EOS
        <payment:card>
          <payment:holderName>%s</payment:holderName>
          <payment:number>%s</payment:number>
          <payment:cvc>%s</payment:cvc>
          <payment:expiryYear>%s</payment:expiryYear>
          <payment:expiryMonth>%02d</payment:expiryMonth>
        </payment:card>
EOS


      # @private
      INSTALLMENTS_PARTIAL = <<EOS
        <payment:installments>
          <common:value>%s</common:value>
        </payment:installments>
EOS

      # @private
      ENCRYPTED_CARD_PARTIAL = <<EOS
        <additionalAmount xmlns="http://payment.services.adyen.com" xsi:nil="true" />
        <additionalData xmlns="http://payment.services.adyen.com">
          <entry>
            <key xsi:type="xsd:string">card.encrypted.json</key>
            <value xsi:type="xsd:string">%s</value>
          </entry>
        </additionalData>
EOS

      # @private
      ENABLE_RECURRING_CONTRACTS_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING,ONECLICK</payment:contract>
        </payment:recurring>
EOS

      # @private
      RECURRING_PAYMENT_BODY_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:shopperInteraction>ContAuth</payment:shopperInteraction>
EOS

      # @private
      ONE_CLICK_PAYMENT_BODY_PARTIAL = <<EOS
        <payment:recurring>
          <payment:contract>RECURRING,ONECLICK</payment:contract>
        </payment:recurring>
        <payment:selectedRecurringDetailReference>%s</payment:selectedRecurringDetailReference>
        <payment:card>
          <payment:cvc>%s</payment:cvc>
        </payment:card>
EOS

      # @private
      SHOPPER_PARTIALS = {
        :reference              => '<payment:shopperReference>%s</payment:shopperReference>',
        :email                  => '<payment:shopperEmail>%s</payment:shopperEmail>',
        :ip                     => '<payment:shopperIP>%s</payment:shopperIP>',
        :statement              => '<payment:shopperStatement>%s</payment:shopperStatement>',
        :social_security_number => '<payment:socialSecurityNumber>%s</payment:socialSecurityNumber>'
      }

      # @private
      FRAUD_OFFSET_PARTIAL = '<payment:fraudOffset>%s</payment:fraudOffset>'

      # @private
      ENROLLED_3D_PARTIAL = <<EOS
        <payment:md>%s</payment:md>
        <payment:paResponse>%s</payment:paResponse>
EOS

      # @private
      BROWSER_INFO_PARTIAL = <<EOS
        <payment:browserInfo>
          <payment:acceptHeader>%s</payment:acceptHeader>
          <payment:userAgent>%s</payment:userAgent>
        </payment:browserInfo>
EOS
    end
  end
end
