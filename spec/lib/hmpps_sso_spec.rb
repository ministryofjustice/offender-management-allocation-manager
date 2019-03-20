require 'rails_helper'

# rubocop:disable RSpec/FilePath
describe OmniAuth::Strategies::HmppsSso do
  let(:app) {
    Rack::Builder.new do |b|
      b.run ->(_env) { [200, {}, ['Hello']] }
    end.to_app
  }

  subject(:strategy) do
    described_class.new(app, 'client_id', 'secret')
  end

  context 'when methods' do
    context 'when #info' do
      it 'returns a hash with the username, active caseload, caseloads and email address' do
        leeds_prison = 'LEI'
        username = 'Fred'
        caseloads = { 'LEI' => '', 'RNI' => '' }
        response = double(
          'staff_details',
          active_nomis_caseload: leeds_prison,
          nomis_caseloads: caseloads,
          username: username
        )

        allow(Nomis::Custody::UserApi).to receive(:user_details).and_return(response)
        allow(strategy).to receive(:username).and_return(username)
        allow(strategy).to receive(:decode_roles).and_return(['ROLE_ALLOC_MGR'])

        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:active_caseload]).to eq(leeds_prison)
      end

      it 'sets active caseload from nomis caseloads if not present' do
        leeds_prison = 'LEI'
        username = 'Frank'
        caseloads = { 'LEI' => '', 'RNI' => '' }
        response = double(
            'staff_details',
            active_nomis_caseload: nil,
            nomis_caseloads: caseloads,
            username: username
        )

        allow(Nomis::Custody::UserApi).to receive(:user_details).and_return(response)
        allow(strategy).to receive(:username).and_return(username)
        allow(strategy).to receive(:decode_roles).and_return(['ROLE_ALLOC_MGR'])

        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:active_caseload]).to eq(leeds_prison)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
