require 'test_helper'

class EppDomainRenewBaseTest < EppTestCase
  def setup
    @domain_schema_version = '1.3'
  end

  self.use_transactional_tests = false

  def test_renews_domain
    travel_to Time.zone.parse('2010-07-05')
    domain = domains(:shop)
    original_valid_to = domain.valid_to
    default_renewal_period = 1.year

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="y">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    post epp_renew_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml

    domain.reload

    assert_epp_response :completed_successfully
    assert_equal original_valid_to + default_renewal_period, domain.valid_to
  end

  def test_renews_domain_if_update_prohibited
    travel_to Time.zone.parse('2010-07-05')
    domain = domains(:shop)
    original_valid_to = domain.valid_to
    default_renewal_period = 1.year
    domain.statuses << DomainStatus::SERVER_UPDATE_PROHIBITED
    domain.save

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="y">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    post epp_renew_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml

    domain.reload

    assert_epp_response :completed_successfully
    assert_equal original_valid_to + default_renewal_period, domain.valid_to
    assert domain.statuses.include? DomainStatus::SERVER_UPDATE_PROHIBITED
  end

  def test_domain_renew_if_hold_status_has_notes
    travel_to Time.zone.parse('2010-07-05')
    domain = domains(:shop)
    original_valid_to = domain.valid_to
    default_renewal_period = 1.year
    domain.statuses << DomainStatus::SERVER_HOLD
    domain.status_notes["serverHold"] = "test"
    domain.save

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="y">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    post epp_renew_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml

    domain.reload

    assert_epp_response :completed_successfully
    assert_equal original_valid_to + default_renewal_period, domain.valid_to
    assert domain.statuses.include? DomainStatus::SERVER_HOLD
  end

  def test_domain_renew_if_hold_status_do_not_has_notes
    travel_to Time.zone.parse('2010-07-05')
    domain = domains(:shop)
    original_valid_to = domain.valid_to
    default_renewal_period = 1.year
    domain.statuses << DomainStatus::SERVER_HOLD
    domain.status_notes["serverHold"] = ""
    domain.save

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="y">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    post epp_renew_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml

    domain.reload

    assert_epp_response :completed_successfully
    assert_equal original_valid_to + default_renewal_period, domain.valid_to
    assert_not domain.statuses.include? DomainStatus::SERVER_HOLD
  end

  def test_domain_cannot_be_renewed_when_invalid
    domain = domains(:invalid)

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.valid_to.to_date}</domain:curExpDate>
              <domain:period unit="m">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    assert_no_changes -> { domain.valid_to } do
      post epp_renew_path, params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
      domain.reload
    end

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :object_status_prohibits_operation
  end

  def test_domain_cannot_be_renewed_when_belongs_to_another_registrar
    domain = domains(:metro)
    session = epp_sessions(:api_bestnames)
    assert_not_equal session.user.registrar, domain.registrar

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.valid_to.to_date}</domain:curExpDate>
              <domain:period unit="m">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    assert_no_changes -> { domain.valid_to } do
      post epp_renew_path, params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => "session=#{session.session_id}" }
      domain.reload
    end

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :authorization_error
  end

  def test_insufficient_funds
    domain = domains(:shop)
    session = epp_sessions(:api_bestnames)
    session.user.registrar.accounts.first.update!(balance: 0)

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="y">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    assert_no_difference -> { domain.valid_to } do
      post epp_renew_path, params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => "session=#{session.session_id}" }
      domain.reload
    end

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :billing_failure
  end

  def test_no_price
    domain = domains(:shop)
    assert_nil Billing::Price.find_by(duration: '2 months')

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="m">2</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    assert_no_changes -> { domain.valid_to } do
      post epp_renew_path, params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
      domain.reload
    end

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :billing_failure
  end

  def test_fails_when_provided_expiration_date_is_wrong
    domain = domains(:shop)
    provided_expiration_date = Date.parse('2010-07-06')
    assert_not_equal provided_expiration_date, domain.valid_to

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{provided_expiration_date}</domain:curExpDate>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    assert_no_changes -> { domain.valid_to } do
      post epp_renew_path, params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
      domain.reload
    end

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml
    assert_epp_response :parameter_value_policy_error
  end

  def test_fails_if_domain_has_renewal_prohibited_statuses
    travel_to Time.zone.parse('2010-07-05')
    domain = domains(:shop)
    domain.statuses << DomainStatus::SERVER_RENEW_PROHIBITED
    domain.save

    original_valid_to = domain.valid_to
    default_renewal_period = 1.year

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <renew>
            <domain:renew xmlns:domain="#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}">
              <domain:name>#{domain.name}</domain:name>
              <domain:curExpDate>#{domain.expire_time.to_date}</domain:curExpDate>
              <domain:period unit="y">1</domain:period>
            </domain:renew>
          </renew>
        </command>
      </epp>
    XML

    post epp_renew_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }

    response_xml = Nokogiri::XML(response.body)
    assert_correct_against_schema response_xml

    domain.reload

    assert_epp_response :object_status_prohibits_operation
    assert_equal original_valid_to, domain.valid_to
  end
end
