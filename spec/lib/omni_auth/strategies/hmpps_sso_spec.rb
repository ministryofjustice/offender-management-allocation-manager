require 'rails_helper'

describe OmniAuth::Strategies::HmppsSso do
  subject(:strategy) do
    described_class.new(app, 'client_id', 'secret')
  end

  let(:app) do
    Rack::Builder.new { |b|
      b.run ->(_env) { [200, {}, ['Hello']] }
    }.to_app
  end

  let(:username) { 'MOIC_POM' }
  let(:staff_id) { 485_926 }

  before do
    stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/#{staff_id}")
      .to_return(body: {
        'staffId': staff_id,
        'generalAccount': {
          'username': username,
          'caseloads': [
            { "id" => "MDI", "name" => "Moorland (HMP & YOI)" },
            { "id" => "NWEB", "name" => "Nomis-web Application" },
            { "id" => "LEI", "name" => "Leeds (HMP)" },
          ],
          'activeCaseload': { "id" => "LEI", "name" => "Leeds (HMP)" }
        }
      }.to_json)
  end

  context 'when methods' do
    before do
      allow(strategy).to receive(:username).and_return(username)
      allow(strategy).to receive(:staff_id).and_return(staff_id)
      allow(strategy).to receive(:decode_roles).and_return(['ROLE_ALLOC_MGR'])
    end

    context 'when #info' do
      it 'returns a hash with the username, active caseload, caseloads and email address' do
        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:staff_id]).to eq(staff_id)
        expect(strategy.info[:active_caseload]).to eq('LEI')
        expect(strategy.info[:caseloads]).to eq(%w[LEI MDI NWEB])
      end
    end
  end
end
