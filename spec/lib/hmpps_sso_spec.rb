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
        emails = ["email@example.com"]
        response = double(
          'staff_details',
          active_nomis_caseload: leeds_prison,
          nomis_caseloads: caseloads,
          username: username,
          emails: emails
        )

        allow(UserService).to receive(:get_user_details).and_return(response)
        allow(strategy).to receive(:username).and_return(username)

        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:active_caseload]).to eq(leeds_prison)
        expect(strategy.info[:emails]).to eq(emails)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
