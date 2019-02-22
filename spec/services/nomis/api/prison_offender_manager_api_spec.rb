require 'rails_helper'

describe Nomis::Api::PrisonOffenderManagerApi do
  it 'can get a of Prison Offender Managers (POMs)',
    vcr: { cassette_name: :pom_api_list_spec  } do
    response = described_class.list('LEI')

    expect(response).to be_instance_of(Array)
    expect(response).to all(be_an Nomis::Models::PrisonOffenderManager)
  end
end
