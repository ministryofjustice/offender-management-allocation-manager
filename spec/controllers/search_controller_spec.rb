require 'rails_helper'

# Note - this is a rubbish test. It doesn't actually test the search controller
# it's part of a spike to demonstrate that we can write controller tests pretty easily
# by hard-wiring the sso_data in the session.
# It might be better to mock slightly higher up than done here - the normal flow of a controller
# test is to setup models and then call the action - the current code doesn't really have a
# nice clean 'data layer' where mocking could be introduced without being a source of defects.
RSpec.describe SearchController, type: :controller do
  # Need to use a different prison than LEI to prevent filling Rails cache with mock data
  let(:prison) { 'WEI' }
  let(:booking_id) { 'booking3' }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }
  let(:elite2listapi) { "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true" }

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
      to_return(status: 200, body: {}.to_json, headers: {})
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
