require 'rails_helper'

describe Nomis::Elite2::UserApi do
  it "gets staff details",
    vcr: { cassette_name: :user_api_staff_details_spec  } do
    username = 'PK000223'

    response = described_class.user_details(username)

    expect(response).to be_kind_of(Nomis::Models::UserDetails)
    expect(response.active_case_load_id).to eq('LEI')
  end
end
