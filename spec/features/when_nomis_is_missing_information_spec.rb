require 'rails_helper'

context 'when NOMIS is missing information' do
  let(:stub_prison_code) { 'LEI' }

  before do
    stub_auth_host = 'http://nomis.mock'
    stub_api_host = 'http://nomis.mock/elite2api/api'
    stub_user_name = 'example_user'
    stub_staff_id = 1
    stub_poms = [{ staffId: 1, position: RecommendationService::PRISON_POM }]
    stub_offenders = [{
      offenderNo: "A1",
      bookingId: 1,
      dateOfBirth: '1990-01-01',
      imprisonmentStatus: 'LIFE'
    }]

    stub_bookings = [{
      bookingId: 1,
      sentenceDetail: {
        releaseDate: 30.years.from_now.iso8601,
        sentenceStartDate: Time.zone.now.iso8601
      }
    }]

    Rails.configuration.nomis_oauth_host = stub_auth_host

    stub_request(:post, "#{stub_auth_host}/auth/oauth/token").
      with(query: { grant_type: 'client_credentials' }).
      to_return(status: 200, body: {}.to_json)

    stub_request(:get, "#{stub_api_host}/users/example_user").
      to_return(status: 200, body: { staffId: stub_staff_id }.to_json)

    stub_request(:get, "#{stub_api_host}/staff/#{stub_staff_id}/emails").
      to_return(status: 200, body: [].to_json)

    stub_request(:get, "#{stub_api_host}/staff/roles/#{stub_prison_code}/role/POM").
      to_return(status: 200, body: stub_poms.to_json)

    stub_request(:get, "#{stub_api_host}/locations/description/#{stub_prison_code}/inmates").
      with(query: { convictedStatus: 'Convicted', returnCategory: true }).
      to_return(status: 200, body: stub_offenders.to_json)

    stub_request(:post, "#{stub_api_host}/offender-sentences/bookings").
      to_return(status: 200, body: stub_bookings.to_json)

    signin_pom_user(stub_user_name)
  end

  describe 'the caseload page' do
    it 'does not error' do
      create(:allocation, nomis_offender_id: "A1", primary_pom_nomis_id: 1)

      visit prison_caseload_index_path(stub_prison_code)

      expect(page).to have_content('Showing 1 - 1 of 1 results')
    end
  end
end
