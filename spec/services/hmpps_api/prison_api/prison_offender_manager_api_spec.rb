require 'rails_helper'

describe HmppsApi::PrisonApi::PrisonOffenderManagerApi do
  let(:staff_id) { 485_636 }
  let(:emails) { ['test@example.com'] }
  let(:pom) { build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', emails:) }

  before do
    stub_poms('LEI', [pom])
    stub_poms('WEI', [])
  end

  it 'gets staff detail' do
    list = described_class.list('LEI')
    response = described_class.staff_detail list.first.staff_id

    expect(response.staff_id).to eq(staff_id)
    expect(response.first_name).to eq("MOIC")
    expect(response.last_name).to eq("POM")
    expect(response.status).to eq("ACTIVE")
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

  describe '#fetch_email_addresses' do
    it "can get a user's email addresses" do
      response = described_class.fetch_email_addresses(staff_id)

      expect(response).to eq(emails)
    end
  end
end
