require 'rails_helper'

describe SignonIdentity, model: true do
  let(:time_stamp) { 123_456 }
  let(:user_auth_data) { double('user_auth_data', username: 'Fred', caseload: 'LEI') }
  let(:credentials) { double('credentials', expires_at: time_stamp) }
  let(:omniauth_data) do
    { 'info' => user_auth_data, 'credentials' => credentials }
  end
  let(:signon_identity) { SignonIdentity.from_omniauth(omniauth_data) }

  it 'creates a SignonIdentity instance' do
    expect(signon_identity).to be_a_kind_of(SignonIdentity)
  end

  it 'creates session data' do
    session = {
      username: 'Fred',
      caseload: 'LEI',
      expiry: time_stamp
    }

    expect(signon_identity.to_session).to eq(session)
  end
end
