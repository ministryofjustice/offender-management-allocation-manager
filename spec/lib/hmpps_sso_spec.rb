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
    let(:user_name) { double('user_name') }

    let(:token_info) do
      {
        'user_name' => user_name
      }
    end

    context 'when #token_info' do
      before do
        allow(strategy).to receive(:token_info).and_return(token_info)
      end

      it 'returns a hash with the user name' do
        expect(strategy.info).to eq(
          username: user_name)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
