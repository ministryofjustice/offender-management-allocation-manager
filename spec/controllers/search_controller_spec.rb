require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  # Need to use a different prison than LEI to prevent filling Rails cache with mock data
  let(:prison) { 'WEI' }
  let(:booking_id) { 'booking3' }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
  let(:elite2listapi) { "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true" }
  let(:elite2bookingsapi) { "#{elite2api}/offender-sentences/bookings" }

  before do
    allow(Nomis::Oauth::TokenService).to receive(:valid_token).and_return(OpenStruct.new(access_token: 'token'))
    session[:sso_data] = { 'expiry' => Time.zone.now + 1.day,
                           'roles' => ['ROLE_ALLOC_MGR'],
                           'caseloads' => [prison] }
  end

  it 'can search' do
    stub_request(:get, elite2listapi).
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '1',
          'Page-Offset' => '1'
        }).
      to_return(status: 200, body: {}.to_json, headers: { 'Total-Records' => '31' })

    stub_request(:get, elite2listapi).
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '200',
          'Page-Offset' => '0'
        }).
      to_return(status: 200,
                body: [{ "bookingId": 754_207, "bookingNo": "K09211", "offenderNo": "G7806VO", "firstName": "ONGMETAIN",
                         "lastName": "ABDORIA", "dateOfBirth": "1990-12-06",
                         "age": 28, "agencyId": "LEI", "assignedLivingUnitId": 13_139, "assignedLivingUnitDesc": "E-5-004",
                         "facialImageId": 1_392_829,
                         "categoryCode": "C", "imprisonmentStatus": "LR", "alertsCodes": [], "alertsDetails": [], "convictedStatus": "Convicted" }
                ].to_json)
    stub_request(:post, elite2bookingsapi).
      with(
        body: "[754207]",
        headers: {
          'Authorization' => 'Bearer token',
          'Content-Type' => 'application/json',
          'Expect' => '',
          'User-Agent' => 'Faraday v0.15.4'
        }).
      to_return(status: 200, body: [
        { "bookingId": 754_207, "offenderNo": "G4912VX", "firstName": "EASTZO", "lastName": "AUBUEL", "agencyLocationId": "LEI",
          "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                              "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                              "bookingId": 524_586, "sentenceStartDate": "2009-02-08", "automaticReleaseOverrideDate": "2012-03-17",
                              "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                              "releaseDate": "2012-03-17" }, "dateOfBirth": "1953-04-15", "agencyLocationDesc": "LEEDS (HMP)",
          "internalLocationDesc": "A-4-013", "facialImageId": 1_399_838 }].to_json, headers: {})

    stub_request(:get, elite2listapi).
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '200',
          'Page-Offset' => '200'
        }).
      to_return(status: 200, body: {}.to_json, headers: {})
    stub_request(:get, "#{elite2api}/staff/roles/#{prison}/role/POM").
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        }).
      to_return(status: 200, body: {}.to_json, headers: {})

    get :search, params: { prison_id: prison, q: 'Cal' }
    expect(response.status).to eq(200)
    expect(response).to be_successful

    expect(assigns(:q)).to eq('Cal')
    expect(assigns(:offenders).size).to eq(0)

    actual = assigns(:page_meta)
    expect(actual.size).to eq(10)
    expect(actual.total_pages).to eq(0)
    expect(actual.total_elements).to eq(0)
    expect(actual.number).to eq(1)
    expect(actual.items_on_page).to eq(0)
  end
end
