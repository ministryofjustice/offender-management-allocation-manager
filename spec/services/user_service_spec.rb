require 'rails_helper'

RSpec.describe UserService, vcr: { cassette_name: :user_service_get_user_details }  do
  it "Gets a users details" do
    username = 'PK000223'
    user = described_class.get_user_details(username)

    expect(user.staff_id).to eq(485_637)
    expect(user.emails).to eq("[\"kath.pobee-norris@digital.justice.gov.uk\"]")
  end
end
