require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  # Need to use a different prison than LEI to prevent filling Rails cache with mock data }
  let(:prison) { 'WEI' }
  let(:booking_id) { 'booking3' }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
  let(:elite2listapi) { "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true" }
  let(:elite2bookingsapi) { "#{elite2api}/offender-sentences/bookings" }

  context 'when user is a POM ' do
    let(:poms) {
      [
        build(:pom,
              firstName: 'Alice',
              position: RecommendationService::PRISON_POM,
              staffId: 1
        )
      ]
    }

    before do
      stub_poms(prison, poms)
      stub_signed_in_pom(prison, 1, 'alice')
      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/users/").
        with(headers: { 'Authorization' => 'Bearer token' }).
        to_return(status: 200, body: { staffId: 1 }.to_json, headers: {})
    end

    it 'user is redirected to caseload' do
      get :search, params: { prison_id: prison, q: 'Cal' }
      expect(response).to redirect_to(prison_staff_caseload_index_path(prison, 1, q: 'Cal'))
    end
  end

  context 'when user is an SPO ' do
    before do
      stub_sso_data(prison, 'alice')
    end

    it 'can search' do
      offenders = [{ "bookingId": 754_207, "bookingNo": "K09211", "offenderNo": "G7806VO", "firstName": "ONGMETAIN",
                     "lastName": "ABDORIA", "dateOfBirth": "1990-12-06",
                     "age": 28, "agencyId": "LEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                     "facialImageId": 1_392_829,
                     "categoryCode": "C", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" }]
      bookings =  [{ "bookingId": 754_207, "offenderNo": "G4912VX", "firstName": "EASTZO", "lastName": "AUBUEL", "agencyLocationId": "LEI",
                     "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                                         "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                                         "bookingId": 754_207, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                                         "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                                         "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
                     "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }]

      stub_offenders_for_prison(prison, offenders, bookings)

      stub_request(:get, "#{elite2api}/staff/roles/#{prison}/role/POM").
        with(
          headers: {
            'Page-Limit' => '100',
            'Page-Offset' => '0'
          }).
        to_return(status: 200, body: {}.to_json, headers: {})

      get :search, params: { prison_id: prison, q: 'Cal' }
      expect(response.status).to eq(200)
      expect(response).to be_successful

      expect(assigns(:q)).to eq('Cal')
      expect(assigns(:offenders).size).to eq(0)
    end
  end
end
