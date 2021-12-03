require 'test_helper'

class EppLoginTest < EppTestCase
  setup do
    @original_sessions_per_registrar_setting = EppSession.sessions_per_registrar
    @domain_schema_version = '1.3'
  end

  teardown do
    EppSession.sessions_per_registrar = @original_sessions_per_registrar_setting
  end

  def test_logging_in_with_correct_credentials_creates_new_session
    user = users(:api_bestnames)
    new_session_id = 'new-session-id'

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <login>
            <clID>#{user.username}</clID>
            <pw>#{user.plain_text_password}</pw>
            <options>
              <version>1.0</version>
              <lang>en</lang>
            </options>
            <svcs>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}</objURI>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'contact-ee', for_version: '1.1')}</objURI>
              <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
              <objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI>
            </svcs>
          </login>
        </command>
      </epp>
    XML
    assert_difference 'EppSession.count' do
      post '/epp/session/login', params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => "session=#{new_session_id}" }
    end
    assert_epp_response :completed_successfully
    session = EppSession.last
    assert_equal new_session_id, session.session_id
    assert_equal user, session.user
  end

  def test_user_cannot_login_again
    session = epp_sessions(:api_bestnames)
    user = session.user

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <login>
            <clID>#{user.username}</clID>
            <pw>#{user.plain_text_password}</pw>
            <options>
              <version>1.0</version>
              <lang>en</lang>
            </options>
            <svcs>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}</objURI>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'contact-ee', for_version: '1.1')}</objURI>
              <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
              <objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI>
            </svcs>
          </login>
        </command>
      </epp>
    XML

    assert_no_difference 'EppSession.count' do
      post '/epp/session/login', params: { frame: request_xml },
           headers: { HTTP_COOKIE: "session=#{session.session_id}" }
    end
    assert_epp_response :use_error
  end

  def test_user_cannot_login_with_wrong_credentials
    user = users(:api_bestnames)
    wrong_password = 'a' * ApiUser.min_password_length
    assert_not_equal wrong_password, user.plain_text_password

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <login>
            <clID>#{user.username}</clID>
            <pw>#{wrong_password}</pw>
            <options>
              <version>1.0</version>
              <lang>en</lang>
            </options>
            <svcs>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}</objURI>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'contact-ee', for_version: '1.1')}</objURI>
              <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
              <objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI>
            </svcs>
          </login>
        </command>
      </epp>
    XML

    assert_no_difference 'EppSession.count' do
      post '/epp/session/login', params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => 'session=new-session-id' }
    end
    assert_epp_response :authentication_error_server_closing_connection
  end

  def test_password_change
    user = users(:api_bestnames)
    new_password = 'a' * ApiUser.min_password_length
    assert_not_equal new_password, user.plain_text_password

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <login>
            <clID>#{user.username}</clID>
            <pw>#{user.plain_text_password}</pw>
            <newPW>#{new_password}</newPW>
            <options>
              <version>1.0</version>
              <lang>en</lang>
            </options>
            <svcs>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}</objURI>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'contact-ee', for_version: '1.1')}</objURI>
              <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
              <objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI>
            </svcs>
          </login>
        </command>
      </epp>
    XML
    post '/epp/session/login', params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=new-session-id' }
    user.reload

    assert_epp_response :completed_successfully
    assert_equal new_password, user.plain_text_password
  end

  def test_user_cannot_login_when_max_allowed_sessions_per_registrar_is_exceeded
    user = users(:api_bestnames)
    eliminate_effect_of_existing_epp_sessions
    EppSession.sessions_per_registrar = 1
    EppSession.create!(session_id: 'any', user: user)

    request_xml = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee', for_version: '1.0')}">
        <command>
          <login>
            <clID>#{user.username}</clID>
            <pw>#{user.plain_text_password}</pw>
            <options>
              <version>1.0</version>
              <lang>en</lang>
            </options>
            <svcs>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @domain_schema_version)}</objURI>
              <objURI>#{Xsd::Schema.filename(for_prefix: 'contact-ee', for_version: '1.1')}</objURI>
              <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>
              <objURI>urn:ietf:params:xml:ns:keyrelay-1.0</objURI>
            </svcs>
          </login>
        </command>
      </epp>
    XML

    assert_no_difference 'EppSession.count' do
      post '/epp/session/login', params: { frame: request_xml },
           headers: { 'HTTP_COOKIE' => 'session=new-session-id' }
    end
    assert_epp_response :session_limit_exceeded_server_closing_connection
  end

  private

  def eliminate_effect_of_existing_epp_sessions
    EppSession.delete_all
  end
end
