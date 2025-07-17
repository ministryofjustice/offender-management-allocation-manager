require 'rails_helper'

describe HmppsApi::PrisonApi::PrisonOffenderManagerApi do
  let(:staff_id) { 485_636 }
  let(:emails) { ['test@example.com'] }
  let(:pom) { build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', emails:) }

  before do
    stub_poms('LEI', [pom])
    stub_poms('WEI', [])
  end

  it 'can get an Array of Prison Offender Managers (POMs)' do
    response = described_class.list('LEI')

    expect(response).to be_instance_of(Array)
    expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
  end

  it 'can handle no POMs for a prison' do
    response = described_class.list('WEI')

    expect(response).to be_instance_of(Array)
    expect(response.count).to eq(0)
    expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
  end
end
