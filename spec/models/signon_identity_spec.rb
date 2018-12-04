require 'rails_helper'

describe SignonIdentity, model: true do
  let(:user_auth_data) { double('user_auth_data', username: 'Fred') }
  let(:omniauth_data) { double('omniauth_data') }
  let(:signon_identity) { SignonIdentity.from_omniauth(omniauth_data) }

  it 'creates a SignonIdentity instance' do
    allow(omniauth_data).to receive(:fetch).and_return(user_auth_data)
    expect(signon_identity).to be_a_kind_of(SignonIdentity)
  end

  it 'creates session data' do
    allow(omniauth_data).to receive(:fetch).and_return(user_auth_data)

    session = {
      username: 'Fred'
    }

    expect(signon_identity.to_session).to eq(session)
  end
end
