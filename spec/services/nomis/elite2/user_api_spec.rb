require 'rails_helper'

describe Nomis::Elite2::UserApi do
  describe '#fetch_email_addresses' do
    it "can get a user's single email address",
      vcr: { cassette_name: :elite2_staff_api_get_email } do

      response = described_class.fetch_email_addresses(485_637)

      expect(response).to eq(["kath.pobee-norris@digital.justice.gov.uk"])
    end

    it "can get multiple email addresses for a user",
      vcr: { cassette_name: :elite2_staff_api_get_emails } do

      response = described_class.fetch_email_addresses(485_595)

      expect(response).to eq(["tobby.retrallick@digitals.justice.gov.uk", "toby.retallick@digital.justice.gov.uk"])
    end
  end
end
