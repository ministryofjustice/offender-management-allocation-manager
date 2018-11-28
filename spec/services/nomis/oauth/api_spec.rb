require 'rails_helper'

describe Nomis::Oauth::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it 'fetches an auth token' do
    access_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpbnRlcm5hbFVzZXIiOmZhbHNlLCJzY29wZSI6WyJyZWFkIiwid3JpdGUiXSwiZXhwIjoxNTQzNDAzODA5LCJhdXRob3JpdGllcyI6WyJST0xFX1NZU1RFTV9SRUFEX09OTFkiXSwianRpIjoiYTlmMjQ0NzEtODU3ZC00MmM0LWJkZWYtZGNjOTM2ZjcyOTU5IiwiY2xpZW50X2lkIjoib2ZmZW5kZXItbWFuYWdlbWVudC1hbGxvY2F0aW9uLW1hbmFnZXIifQ.MKcRwW8mAvS3TC5Y1Nv-0mm5r3FvuTDCjgDFSjhhPf1dJdMl8xnw88czTxBm66t1w-1KUFyuWMsYQKL53NBk63FWmrbDEwhFUUQDUrht968LTwfiR1QGJQdYC9HjTqnZiEwOdIrwnGv2PbtG5nlbyB35FlMqoohqw33H2KYZCi5a9n6YZ3MD2Q8E2Q7Teg6VeOjiI1iQdeAbR3XBZh0q3JzH7g-2SVwtLHk0vqWatk1tuHRDBiJ8RNWgWLk0m2W0gVyViFniNWgH5vjlCfxt1g8Jph4HDMTGGrtKtQE3JnHf2OdcCj3LxQk_a3FbBiCxJX10RNXLWaehnWjaZ2yXLA"

    allow_any_instance_of(Nomis::Oauth::Client).to receive(:post).and_return(
      'access_token' => access_token
    )

    token = described_class.fetch_new_auth_token

    expect(token).to be_kind_of(Nomis::Oauth::Token)
    expect(token.access_token).to eq(access_token)
  end
end
