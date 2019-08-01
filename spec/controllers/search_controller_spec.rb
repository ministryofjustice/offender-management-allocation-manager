require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  let(:prison) { 'RSI' }
  let(:booking_id) { 'booking3' }
  let(:elite2api) { 'https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api' }

  before do
    allow(Nomis::Oauth::TokenService).to receive(:valid_token).and_return(OpenStruct.new(access_token: 'token'))
    session[:sso_data] = { 'expiry' => Time.zone.now + 1.day,
                           'roles' => ['ROLE_ALLOC_MGR'],
                           'caseloads' => [prison] }
  end

  it 'can search' do
    stub_request(:get, "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true").
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '1',
          'Page-Offset' => '1'
        }).
      to_return(status: 200, body: {}.to_json, headers: { 'Total-Records' => '931' })

    stub_request(:get, "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true").
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Expect' => '',
          'Page-Limit' => '200',
          'Page-Offset' => '0'
        }).
      to_return(status: 200, body: {}.to_json, headers: {})
    stub_request(:get, "#{elite2api}/locations/description/#{prison}/inmates?convictedStatus=Convicted&returnCategory=true").
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
