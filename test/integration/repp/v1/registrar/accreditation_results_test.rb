require 'test_helper'

class ReppV1AccreditationResultsTest < ActionDispatch::IntegrationTest
  TEMPARY_SECRET_KEY = 'tempary-secret-key'.freeze

  def setup
    @user = users(:api_bestnames)

    token = "Basic #{TEMPARY_SECRET_KEY}"

    @auth_headers = { 'Authorization' => token }
  end

  def test_should_return_valid_response
    post '/repp/v1/registrar/accreditation/push_results',
      headers: @auth_headers,
      params: {accreditation_result: {username: @user.username, result: true} }
    json = JSON.parse(response.body, symbolize_names: true)

    assert_response :ok
    assert_equal json[:data][:user][:username], @user.username
    assert_equal json[:data][:result], "true"
    assert_equal json[:data][:message], "Accreditation info successfully added"
  end

  def test_should_return_valid_response_invalid_authorization
    post '/repp/v1/registrar/accreditation/push_results',
      headers: { 'Authorization' => 'Basic tempary-secret-ke'},
      params: {accreditation_result: {username: @user.username, result: true} }
    json = JSON.parse(response.body, symbolize_names: true)

    assert_response :unauthorized

    assert_equal json[:code], 2202
    assert_equal json[:message], 'Invalid authorization information'
  end

  def test_should_return_valid_response_record_exception
    post '/repp/v1/registrar/accreditation/push_results',
      headers: @auth_headers,
      params: {accreditation_result: { username: "chungachanga", result: true} }
    json = JSON.parse(response.body, symbolize_names: true)

    assert_response :ok

    assert_equal json[:code], 2303
    assert_equal json[:message], "Object 'chungachanga' does not exist"
  end
end
