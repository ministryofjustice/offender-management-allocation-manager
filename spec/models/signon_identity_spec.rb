require 'rails_helper'

describe SignonIdentity, model: true do
  let(:time_stamp) { 123_456 }
  let(:user_auth_data) do
    double('user_auth_data',
           username: 'MOIC_POM',
           active_caseload: 'LEI',
           caseloads: %w[LEI RNI],
           roles: ['ROLE_ALLOC_MGR']
          )
  end
  let(:credentials) { double('credentials', expires_at: time_stamp, token: 'fake-user-token') }
  let(:omniauth_data) do
    { 'info' => user_auth_data, 'credentials' => credentials }
  end
  let(:signon_identity) { described_class.from_omniauth(omniauth_data) }

  it 'creates a SignonIdentity instance' do
    expect(signon_identity).to be_a_kind_of(described_class)
  end

  it 'does not crash if from_omniauth fails' do
    ident = described_class.from_omniauth(nil)
    expect(ident).to be_nil
  end

  it 'can be serialized with #attributes' do
    session = {
      username: 'MOIC_POM',
      active_caseload: 'LEI',
      caseloads: %w[LEI RNI],
      expiry: time_stamp,
      token: 'fake-user-token',
      roles: ['ROLE_ALLOC_MGR']
    }

    expect(signon_identity.attributes).to eq(session)
  end
end
