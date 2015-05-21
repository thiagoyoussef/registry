require 'rails_helper'

feature 'DomainDeleteConfirm', type: :feature do
  context 'as unknown user with domain without token' do
    before :all do
      @domain = Fabricate(:domain)
    end

    it 'should see warning info if token is missing request' do
      visit "/registrant/domain_delete_confirms/#{@domain.id}"
      current_path.should == "/registrant/domain_delete_confirms/#{@domain.id}"
      page.should have_text('Domain verification not available')
    end

    it 'should see warning info if token is missing request' do
      visit "/registrant/domain_delete_confirms/#{@domain.id}"
      current_path.should == "/registrant/domain_delete_confirms/#{@domain.id}"
      page.should have_text('Domain verification not available')
    end
  end

  context 'as unknown user with domain with token' do
    before :all do
      @domain = Fabricate(
        :domain, 
        registrant_verification_token: '123', 
        registrant_verification_asked_at: Time.zone.now
      )
      @domain.domain_statuses.create(value: DomainStatus::PENDING_DELETE)
    end

    it 'should see warning info if token is missing in request' do
      visit "/registrant/domain_delete_confirms/#{@domain.id}?token=wrong_token"
      current_path.should == "/registrant/domain_delete_confirms/#{@domain.id}"
      page.should have_text('Domain verification not available')
    end

    it 'should show domain info and confirm buttons' do
      visit "/registrant/domain_delete_confirms/#{@domain.id}?token=123"
      current_path.should == "/registrant/domain_delete_confirms/#{@domain.id}"
      page.should_not have_text('Domain verification not available')
    end
  end
end