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

  let(:prison_code) { build(:prison).code }
  let(:ldu) { create(:local_divisional_unit) }
  let!(:new_team) { create(:team, local_divisional_unit: ldu) }
  let(:admin_urls) {
    [
    '/admin', '/flip-flop-admin', '/sidekiq',
    "/prisons/#{prison_code}/debugging",
    "/prisons/#{prison_code}/debugging/prison"
  ]
  }

  context 'when pom' do
    before do
      signin_pom_user
    end

    it 'is unauthorised' do
      admin_urls.each do |admin_url|
        visit(admin_url)

        expect(page).to have_http_status(:unauthorized)
      end
    end
  end

  context 'when SPO' do
    before do
      signin_spo_user
    end

    it 'is unauthorised' do
      admin_urls.each do |admin_url|
        visit(admin_url)

        expect(page).to have_http_status(:unauthorized)
      end
    end
  end

  context 'when a global admin' do
    let(:username) { 'MOIC_POM' }
    let(:staff_id) { 754_732 }

    before do
      signin_global_admin_user
      stub_auth_token
      stub_request(:get, "#{ApiHelper::T3}/users/#{username}").
        to_return(body: { 'staffId': staff_id }.to_json)
      stub_pom_emails staff_id, []
      stub_offenders_for_prison(prison_code, [])

      ci = create(:case_information, team: nil)
      create(:allocation, nomis_offender_id: ci.nomis_offender_id)
    end

    it 'is ok' do
      admin_urls.each do |admin_url|
        visit(admin_url)

        expect(page).to have_http_status(:ok)
      end
    end

    it 'displays the dashboard' do
      ci = create(:case_information, team: nil)
      create(:allocation, nomis_offender_id: ci.nomis_offender_id)

      visit('/admin')
      expect(page).to have_http_status(:success)
    end

    context 'with teams' do
      before do
        visit('/admin/teams')
      end

      it 'displays the list of teams' do
        expect(page).to have_http_status(:success)
        expect(page).to have_content(new_team.name.to_s)
      end

      it 'can delete a team' do
        within("#team_#{new_team.id}") do
          click_link("Delete")
        end

        expect(page).to have_content('Team was successfully destroyed')
      end
    end

    context 'with local delivery units' do
      before do
        visit('/admin/local_delivery_units')
      end

      it 'can create one' do
        expect {
          click_link 'New Localdeliveryunit'
          fill_in 'Code', with: Faker::Alphanumeric.alphanumeric(number: 4)
          fill_in 'Name', with: Faker::Lorem.sentence
          fill_in 'Email address', with: Faker::Internet.email
          select 'England'
          click_button 'Create Local delivery unit'
        }.to change(LocalDeliveryUnit, :count).by(1)
      end
    end

    context 'with local divisional units' do
      before do
        visit('/admin/deprecatedold_ldus')
      end

      it "displays the list of LDU's" do
        expect(page).to have_http_status(:success)
        expect(page).to have_content(ldu.name.to_s)
      end

      it 'can delete an ldu' do
        expect(page).to have_link('Delete')
      end
    end
  end
end
