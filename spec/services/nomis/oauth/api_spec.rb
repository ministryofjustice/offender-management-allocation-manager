require 'rails_helper'

describe Nomis::Oauth::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches an auth token', vcr: { cassette_name: :token_request } do
    encrypted_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbnRlcm5hbFVzZXIiOmZhbHNlLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQzMzM3ODE0LCJhdXRob3JpdGllcyI6WyJST0xFX1NZU1RFTV9SRUFEX09OTFkiXSwianRpIjoiYTMxMTNkY2EtNGI1MS00MjNlLThlZWEtODA4YTJkYjk3Y2FlIiwiY2xpZW50X2lkIjoib2ZmZW5kZXItbWFuYWdlbWVudC1hbGxvY2F0aW9uLW1hbmFnZXIifQ.XVPe7kflDcdYDCJbrUya1KdFU3VUz_QVbyz3sEk7mOgtzT5wo6Dp2_Ijl4nbxeBPrAguRvJrm3i6SQBlwqcoaD2UnVdI2izQwUgt6swtqR3i0MTMh3gj8Be84-Vgz4KbG-NTpisBqMYktq17bMqoGvRsEvX2n1ZlWJsvJ2q5G6mq_R0BwA89iXrU97iNwgb5XZqjMdDKn9ec8ssWPxLsxNeqM5bm27kXqkuuZ2ceULjhGX7xH5xM4WR6MsK8njmGzcO93rk8PH1WY_HZMrJWmT8cUP_ZyE9doYNWeykucv2x6XyeYhFv45jeE6zlvFA5NGx4WqZcXzDe3ZhOqVVWwA"
    api = described_class.instance
    token = api.fetch_new_auth_token

    expect(token).to be_kind_of(Nomis::Oauth::Token)
    expect(token.access_token).to eq(encrypted_token)
  end
end
