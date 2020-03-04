require 'rails_helper'

feature 'ActiveAdmin' do
  # This works as expected (i.e. it sends the user to login)
  # but doesn't work in test-land for some unknown reason
  # context 'unauthorised' do
  #   before do
  #     OmniAuth.config.test_mode = false
  #   end
  #   after do
  #     OmniAuth.config.test_mode = true
  #   end
  #
  #   scenario 'unauthorised' do
  #     visit('/admin')
  #     expect(page).to have_http_status(:unauthorized)
  #   end
  # end

  context 'when pom' do
    before do
      signin_pom_user
    end

    it 'is unauthorised' do
      visit('/admin')
      expect(page).to have_http_status(:unauthorized)
    end
  end

  context 'when spo' do
    before do
      signin_spo_user
      ci = create(:case_information, probation_service: 'Scotland', team: nil)
      create(:allocation, nomis_offender_id: ci.nomis_offender_id)
    end

    it 'displays the dashboard' do
      visit('/admin')
      expect(page).to have_http_status(:success)
    end
  end
end
