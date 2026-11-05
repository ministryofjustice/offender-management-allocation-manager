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
  let(:user_uuid) { '11111111-2222-3333-4444-555555555555' }

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
      allow(strategy).to receive(:user_uuid).and_return(user_uuid)
    end

    context 'when #info' do
      it 'returns a hash with the username, active caseload, caseloads and email address' do
        expect(strategy.info[:username]).to eq(username)
        expect(strategy.info[:staff_id]).to eq(staff_id)
        expect(strategy.info[:user_uuid]).to eq(user_uuid)
        expect(strategy.info[:active_caseload]).to eq('LEI')
        expect(strategy.info[:caseloads]).to eq(%w[LEI MDI NWEB])
      end
    end
  end

  describe 'callback URL host' do
    %w[http://www.example.com http://127.0.0.1:49123].each do |origin|
      it "keeps mocked sign-in callbacks on #{origin}" do
        env = Rack::MockRequest.env_for("#{origin}/auth/hmpps_sso").merge('rack.session' => {})
        response = strategy.call!(env)

        expect(response[1].fetch('Location')).to eq("#{origin}/auth/hmpps_sso/callback")
      end
    end

    it 'uses the configured application host instead of the request host' do
      allow(OmniAuth.config).to receive(:test_mode).and_return(false)
      allow(OmniAuth.config).to receive(:logger).and_return(Logger.new(nil))

      env = Rack::MockRequest.env_for(
        '/auth/hmpps_sso',
        'HTTP_HOST' => 'attacker.example'
      ).merge('SCRIPT_NAME' => '/mounted', 'rack.session' => {})

      response = strategy.call!(env)
      authorization_uri = URI.parse(response[1].fetch('Location'))
      callback_url = URI.decode_www_form(authorization_uri.query).to_h.fetch('redirect_uri')

      expect(callback_url).to eq("#{Rails.configuration.allocation_manager_host}/mounted/auth/hmpps_sso/callback")
    end
  end
end
