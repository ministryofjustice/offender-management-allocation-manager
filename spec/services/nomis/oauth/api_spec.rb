require 'rails_helper'

describe Nomis::Oauth::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches an auth token', vcr: { cassette_name: :get_token } do
    token = described_class.fetch_new_auth_token

    expect(token).to be_kind_of(Nomis::Oauth::Token)
  end
end
