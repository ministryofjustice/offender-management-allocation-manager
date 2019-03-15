require 'rails_helper'

describe Nomis::Elite2::PrisonOffenderManagerApi do
  it 'can get a of Prison Offender Managers (POMs)',
    vcr: { cassette_name: :pom_api_list_spec  } do
    response = described_class.list('LEI')

    expect(response).to be_instance_of(Array)
    expect(response).to all(be_an Nomis::Models::PrisonOffenderManager)
  end

  it 'can handle no POMs for a prison',
    vcr: { cassette_name: :pom_api_list_spec_none  } do
    response = described_class.list('WEI')

    expect(response).to be_instance_of(Array)
    expect(response.count).to eq(0)
    expect(response).to all(be_an Nomis::Models::PrisonOffenderManager)
  end
end
