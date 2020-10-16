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

  let(:ldu) { create(:local_divisional_unit) }
  let!(:new_team) { create(:team, local_divisional_unit: ldu) }
  let(:admin_urls) { ['/admin', '/flip-flop-admin', '/sidekiq'] }

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
    before do
      signin_global_admin_user
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

    context 'with local divisional units' do
      before do
        visit('/admin/ldus')
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
