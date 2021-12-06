require 'test_helper'

class EppDomainTransferQueryTest < EppTestCase
  setup do
    @domain_schema_version = '1.3'
  end

  def test_returns_domain_transfer_details
    post epp_transfer_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    xml_doc = Nokogiri::XML(response.body)

    assert_correct_against_schema xml_doc

    assert_epp_response :completed_successfully
    assert_equal 'shop.test', xml_doc.xpath('//domain:name', 'domain' => "#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}").text
    assert_equal 'serverApproved', xml_doc.xpath('//domain:trStatus', 'domain' => "#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}").text
    assert_equal 'goodnames', xml_doc.xpath('//domain:reID', 'domain' => "#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}").text
    assert_equal 'bestnames', xml_doc.xpath('//domain:acID', 'domain' => "#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}").text
  end

  def test_wrong_transfer_code
    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <transfer op="query">
            <domain:transfer xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>shop.test</domain:name>
              <domain:authInfo>
                <domain:pw>wrong</domain:pw>
              </domain:authInfo>
            </domain:transfer>
          </transfer>
        </command>
      </epp>
    XML

    post epp_transfer_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :invalid_authorization_information
  end

  def test_no_domain_transfer
    domains(:shop).transfers.delete_all
    post epp_transfer_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :object_does_not_exist
  end

  private

  def request_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <transfer op="query">
            <domain:transfer xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>shop.test</domain:name>
              <domain:authInfo>
                <domain:pw>65078d5</domain:pw>
              </domain:authInfo>
            </domain:transfer>
          </transfer>
        </command>
      </epp>
    XML
  end
end
