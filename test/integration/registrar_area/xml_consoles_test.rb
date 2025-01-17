require 'test_helper'

class RegistrarXmlConsolesIntegrationTest < ApplicationIntegrationTest
  setup do
    sign_in users(:api_bestnames)
  end

  def test_check_schema_path
    post registrar_xml_console_path,  params: { frame: payload },
                                      headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }

    assert_response :ok
  end

  def test_load_schema_path
    get load_xml_registrar_xml_console_path, params: { obj: 'domain', epp_action: 'update' }

    assert_response :ok
    assert_equal update_payload, response.body
  end

  private

  def payload
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="https://epp.tld.ee/schema/epp-ee-1.0.xsd">
        <command>
          <check>
            <domain:check xmlns:domain="https://epp.tld.ee/schema/domain-ee-1.1.xsd">
              <domain:name>auction.test</domain:name>
            </domain:check>
          </check>
        </command>
      </epp>
    XML
  end

    def wrong_payload
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="https://epp.tld.ee/schema/epp-ee-1.0.xsd">
        <command>
          <check>
            <domain:check xmlns:domain="https://eppdsfsdfsdf.tld.ee/schema/domain-ee-1.1.xsd">
              <domain:name>auction.test</domain:name>
            </domain:check>
          </check>
        </command>
      </epp>
    XML
  end

  def update_payload
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="https://epp.tld.ee/schema/epp-ee-1.0.xsd">
        <command>
          <update>
            <domain:update
             xmlns:domain="https://epp.tld.ee/schema/domain-ee-1.2.xsd">
              <domain:name>example.ee</domain:name>
              <domain:add>
                <domain:ns>
                  <domain:hostAttr>
                    <domain:hostName>ns1.example.com</domain:hostName>
                  </domain:hostAttr>
                  <domain:hostAttr>
                    <domain:hostName>ns2.example.com</domain:hostName>
                  </domain:hostAttr>
                </domain:ns>
                <domain:contact type="tech">mak21</domain:contact>
              </domain:add>
              <domain:rem>
                <domain:ns>
                  <domain:hostAttr>
                    <domain:hostName>ns1.example.net</domain:hostName>
                  </domain:hostAttr>
                </domain:ns>
                <domain:contact type="tech">mak21</domain:contact>
              </domain:rem>
              <domain:chg>
                <domain:registrant>mak21</domain:registrant>
                <domain:authInfo>
                  <domain:pw>newpw</domain:pw>
                </domain:authInfo>
              </domain:chg>
            </domain:update>
          </update>
          <extension>
            <secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1">
              <secDNS:rem>
                <secDNS:keyData>
                  <secDNS:flags>257</secDNS:flags>
                  <secDNS:protocol>3</secDNS:protocol>
                  <secDNS:alg>8</secDNS:alg>
                  <secDNS:pubKey>700b97b591ed27ec2590d19f06f88bba700b97b591ed27ec2590d19f</secDNS:pubKey>
                </secDNS:keyData>
              </secDNS:rem>
            </secDNS:update>
            <eis:extdata xmlns:eis="https://epp.tld.ee/schema/eis-1.0.xsd">
              <eis:legalDocument type="pdf">
                dGVzdCBmYWlsCg==
              </eis:legalDocument>
            </eis:extdata>
          </extension>
          <clTRID>test_bestnames-#{Time.zone.now.to_i}</clTRID>
        </command>
      </epp>
    XML
  end
end
