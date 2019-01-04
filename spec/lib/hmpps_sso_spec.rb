require 'rails_helper'

# rubocop:disable RSpec/FilePath
describe OmniAuth::Strategies::HmppsSso do
  let(:app){
    Rack::Builder.new do |b|
      b.run ->(_env) { [200, {}, ['Hello']] }
    end.to_app
  }

  subject(:strategy) do
    described_class.new(app, 'client_id', 'secret')
  end

  context 'when methods' do
    context 'when #info' do
      it 'returns a hash with the user name and caseload' do
        leeds_prison = 'LEI'
        username = 'Fred'
        response = Nomis::Custody::ApiResponse.new(
          double('staff_details',
            active_nomis_caseload: leeds_prison,
            username: username
          )
        )

        allow(Nomis::Custody::Api).to receive(:fetch_nomis_staff_details).and_return(response)
        allow(strategy).to receive(:username).and_return(username)

        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:caseload]).to eq(leeds_prison)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
