require 'rails_helper'

describe HmppsApi::Oauth::Token do
  def mock_jwt_token(options = {})
    payload = {
      'internal_user' => false,
      'scope' => %w[read write],
      'exp' => 4.hours.from_now.to_i,
      'client_id' => 'offender-management-allocation-manager',
    }.merge(options)
    allow(JwksDecoder).to receive(:decode_token).and_return([payload])
  end

  it 'can confirm if it is not expired' do
    access_token = mock_jwt_token
    token = described_class.new(access_token: access_token, expires_in: 4.hours)

    expect(token.needs_refresh?).to be(false)
  end

  it 'can confirm if it is expired' do
    access_token = mock_jwt_token('exp' => 4.hours.ago.to_i)
    token = described_class.new(access_token: access_token, expires_in: -4.hours)

    expect(token.needs_refresh?).to be(true)
  end

  it 'can retrieve the payload directly' do
    access_token = mock_jwt_token('exp' => 4.hours.from_now.to_i)
    token = described_class.new(access_token: access_token, expires_in: 4.hours)

    expect(token.needs_refresh?).to be(false)
  end

  describe '#valid?' do
    subject(:token) { described_class.new(access_token:) }

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'with missing token' do
      let(:access_token) { nil }

      it 'logs the error' do
        token.valid?
        expect(Rails.logger).to have_received(:error).with(
          'event=api_access_blocked|Nil JSON web token'
        )
      end

      it 'returns false' do
        expect(token).not_to be_valid
      end
    end

    context 'with an invalid token' do
      let(:access_token) { 'foobar' }

      it 'logs the error' do
        token.valid?
        expect(Rails.logger).to have_received(:error).with(
          'event=api_access_blocked|Not enough or too many segments'
        )
      end

      it 'returns false' do
        expect(token).not_to be_valid
      end
    end
  end

  describe '#valid_token_with_scope?' do
    let(:role) { 'MY_FAB_ROLE' }
    let(:scope) { 'read' }

    let(:token) do
      described_class.new(
        access_token: mock_jwt_token(options),
        expires_in: 4.hours
      )
    end

    before do
      allow(Rails.logger).to receive(:error)
    end

    context 'with required role' do
      let(:options) do
        { 'authorities' => [role] }
      end

      it 'Emits no log error' do
        token.valid_token_with_scope?(scope, role: role)
        expect(Rails.logger).not_to have_received(:error)
      end

      it 'Returns true' do
        expect(token.valid_token_with_scope?(scope, role: role)).to be(true)
      end
    end

    context 'with missing role' do
      let(:options) do
        {}
      end

      it 'Emits a log error' do
        token.valid_token_with_scope?(scope, role: role)
        expect(Rails.logger).to have_received(:error)
      end

      it 'Returns false' do
        expect(token.valid_token_with_scope?(scope, role: role)).to be(false)
      end
    end
  end
end
