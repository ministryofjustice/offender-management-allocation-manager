require 'rails_helper'

describe HmppsApi::Oauth::Token do
  it 'can confirm if it is not expired' do
    access_token = generate_jwt_token
    token = described_class.new(access_token: access_token, expires_in: 4.hours)

    expect(token.needs_refresh?).to be(false)
  end

  it 'can confirm if it is expired' do
    access_token = generate_jwt_token('exp' => 4.hours.ago.to_i)
    token = described_class.new(access_token: access_token, expires_in: -4.hours)

    expect(token.needs_refresh?).to be(true)
  end

  it 'can retrieve the payload directly' do
    access_token = generate_jwt_token('exp' => 4.hours.from_now.to_i)
    token = described_class.new(access_token: access_token, expires_in: 4.hours)

    expect(token.needs_refresh?).to be(false)
  end

  describe '#valid_token_with_scope?' do
    let(:role) { 'MY_FAB_ROLE' }
    let(:scope) { 'read' }

    let(:token) do
      described_class.new(
        access_token: generate_jwt_token(options),
        expires_in: 4.hours
      )
    end

    before do
      allow(Rails.logger).to receive(:warn)
    end

    context 'with required role' do
      let(:options) do
        { 'authorities' => [role] }
      end

      it 'Emits no log warning' do
        token.valid_token_with_scope?(scope, role: role)
        expect(Rails.logger).not_to have_received(:warn)
      end

      it 'Returns true' do
        expect(token.valid_token_with_scope?(scope, role: role)).to be(true)
      end
    end

    context 'with missing role' do
      let(:options) do
        {}
      end

      it 'Emits a log warning' do
        token.valid_token_with_scope?(scope, role: role)
        expect(Rails.logger).to have_received(:warn)
      end

      it 'Returns true' do
        expect(token.valid_token_with_scope?(scope, role: role)).to be(true)
      end
    end
  end
end
