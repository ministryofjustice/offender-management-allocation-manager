RSpec.describe HmppsApi::ActiveCaseloadApi do
  it 'gets current caseload if there is an active one' do
    stub_request(:get, "#{Rails.configuration.prison_api_host}/api/users/me/caseLoads")
      .with(headers: { 'Authorization' => 'Bearer user-token' })
      .to_return(body: '[{"currentlyActive": false, "caseLoadId": "XYZ"}, {"currentlyActive": true, "caseLoadId": "ABC"}]')

    expect(described_class.current_user_active_caseload('user-token')).to eq 'ABC'
  end

  it 'returns nil if there is not an active one' do
    stub_request(:get, "#{Rails.configuration.prison_api_host}/api/users/me/caseLoads")
      .with(headers: { 'Authorization' => 'Bearer user-token' })
      .to_return(body: '[{"currentlyActive": false, "caseLoadId": "XYZ"}, {"currentlyActive": false, "caseLoadId": "ABC"}]')

    expect(described_class.current_user_active_caseload('user-token')).to eq nil
  end
end
