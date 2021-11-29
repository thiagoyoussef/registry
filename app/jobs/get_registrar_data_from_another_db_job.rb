class GetRegistrarDataFromAnotherDbJob < ApplicationJob
  def perform()
    apiusers_from_test = Actions::GetAccrResultsFromAnotherDb.get_list_of_accredated_users

    return if apiusers_from_test.nil?

    apiusers_from_test.each do |api|
      a = ApiUser.find_by(username: api.username, identity_code: api.identity_code)
      Actions::RecordDateOfTest.record_result_to_api_user(a, api.accreditation_date) unless a.nil?
    end

  end


end
