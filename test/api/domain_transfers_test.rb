require 'test_helper'

class Repp::DomainTransfersTest < ActionDispatch::IntegrationTest
  def test_post_to_domain_transfers
    request_params = { format: :json, domainTransfers: [{ domainName: domains(:shop).name, transferCode: domains(:shop).transfer_code }] }
    post '/repp/v1/domain_transfers', request_params, { 'HTTP_AUTHORIZATION' => http_auth_key }
    assert_response :created

    assert_difference -> { domains(:shop).domain_transfers.count } do
      post '/repp/v1/domain_transfers', request_params, { 'HTTP_AUTHORIZATION' => http_auth_key }
    end
  end

  private

  def http_auth_key
    ActionController::HttpAuthentication::Basic.encode_credentials(users(:api_bestnames).username, users(:api_bestnames).password)
  end
end
