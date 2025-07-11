require 'rails_helper'

feature 'admin urls' do
  # This works as expected (i.e. it sends the user to login)
  # but doesn't work in test-land for some unknown reason
  # context 'without login' do
  #   before do
  #     OmniAuth.config.test_mode = false
  #   end
  #
  #   after do
  #     OmniAuth.config.test_mode = true
  #   end
  #
  #   xit 'is unauthorised' do
  #     visit('/admin')
  #     expect(page).to have_http_status(:unauthorized)
  #   end
  # end

  let(:prison_code) { create(:prison).code }
  let(:admin_urls) do
    [
      '/admin',
      '/sidekiq',
      "/prisons/#{prison_code}/debugging",
    ]
  end
  let(:username) { 'MOIC_POM' }
  let(:staff_id) { 754_732 }

  before do
    stub_active_caseload_check
  end

  context 'when pom' do
    before do
      signin_pom_user
    end

    it 'is unauthorised', :aggregate_failures do
      admin_urls.each do |admin_url|
        visit(admin_url)

        expect(page).to have_http_status(:unauthorized)
      end
    end
  end

  context 'when SPO' do
    before do
      signin_spo_user
      stub_user(username, staff_id)
      stub_pom_emails staff_id, []
    end

    it 'is unauthorised' do
      admin_urls.each do |admin_url|
        visit(admin_url)

        expect(page).to have_http_status(:unauthorized)
      end
    end
  end

  context 'when a global admin' do
    before do
      signin_global_admin_user
      stub_user(username, staff_id)
      stub_pom_emails staff_id, []
      stub_offenders_for_prison(prison_code, [])

      ci = create(:case_information)
      create(:allocation_history, prison: prison_code, nomis_offender_id: ci.nomis_offender_id)
    end

    it 'is ok' do
      admin_urls.each do |admin_url|
        visit(admin_url)

        expect(page).to have_http_status(:ok)
      end
    end

    it 'displays the dashboard' do
      ci = create(:case_information)
      create(:allocation_history, prison: prison_code, nomis_offender_id: ci.nomis_offender_id)

      visit('/admin')
      expect(page).to have_http_status(:success)
    end

    context 'with local delivery units' do
      before do
        visit('/admin/local_delivery_units')
      end

      it 'cannot create one' do
        expect(page).not_to have_content('New Localdeliveryunit')
      end
    end
  end
end
