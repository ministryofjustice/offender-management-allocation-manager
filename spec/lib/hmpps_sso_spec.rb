require 'rails_helper'

# rubocop:disable RSpec/FilePath
describe OmniAuth::Strategies::HmppsSso, vcr: { cassette_name: :hmpps_sso } do
  subject(:strategy) do
    described_class.new(app, 'client_id', 'secret')
  end

  let(:app) {
    Rack::Builder.new do |b|
      b.run ->(_env) { [200, {}, ['Hello']] }
    end.to_app
  }

  context 'when methods' do
    context 'when #info' do
      it 'returns a hash with the username, active caseload, caseloads and email address' do
        leeds_prison = 'LEI'
        username = 'MOIC_POM'
        staff_id = 485_926
        caseloads = %w[LEI RNI]
        response = double(
          'staff_details',
          staff_id: staff_id,
          nomis_caseloads: caseloads,
          active_nomis_caseload: leeds_prison,
          username: username
        )
        allow(response).to receive(:staff_id).and_return(staff_id)
        allow(response).to receive(:active_case_load_id).and_return('LEI')

        allow(response).to receive(:nomis_caseloads=)
        allow(response).to receive(:nomis_caseloads).and_return(caseloads)
        allow(HmppsApi::PrisonApi::UserApi).to receive(:user_details).and_return(response)

        allow(strategy).to receive(:username).and_return(username)
        allow(strategy).to receive(:decode_roles).and_return(['ROLE_ALLOC_MGR'])

        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:active_caseload]).to eq(leeds_prison)
      end

      it 'sets active caseload from nomis caseloads if not present' do
        leeds_prison = 'LEI'
        username = 'MOIC_POM'
        staff_id = 485_926
        caseloads = [{ "caseLoadId" => "LEI" }, { "caseLoadId" => "PVI" }, { "caseLoadId" => "SWI" }, { "caseLoadId" => "VEI" }, { "caseLoadId" => "WEI" }]
        response = double(
          'staff_details',
          staff_id: staff_id,
          nomis_caseloads: caseloads,
          active_nomis_caseload: leeds_prison,
          username: username
        )
        allow(response).to receive(:staff_id).and_return(staff_id)
        allow(response).to receive(:active_case_load_id).and_return(nil)

        allow(response).to receive(:nomis_caseloads=)
        allow(response).to receive(:nomis_caseloads).and_return(caseloads)
        allow(HmppsApi::PrisonApi::UserApi).to receive(:user_details).and_return(response)
        allow(strategy).to receive(:username).and_return(username)
        allow(strategy).to receive(:decode_roles).and_return(['ROLE_ALLOC_MGR'])

        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:active_caseload]).to eq(leeds_prison)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
