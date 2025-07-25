require 'rails_helper'

describe HmppsApi::PrisonApi::PrisonOffenderManagerApi do
  let(:staff_id) { 485_636 }
  let(:pom_1) { build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com') }
  let(:pom_2) { build(:pom, staffId: 123_456, firstName: 'Another', lastName: 'POM', primaryEmail: 'another@example.com') }

  context 'when we are not filtering' do
    before do
      stub_poms('LEI', [pom_1, pom_2])
    end

    it 'can get an Array of Prison Offender Managers (POMs)' do
      response = described_class.list('LEI')

      expect(response).to be_instance_of(Array)
      expect(response.count).to eq(2)
      expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
    end
  end

  context 'when we are filtering' do
    before do
      stub_filtered_pom('LEI', pom_1)
    end

    it 'can filter by a specific staff ID' do
      response = described_class.list('LEI', staff_id:)

      expect(response).to be_instance_of(Array)
      expect(response.count).to eq(1)
      expect(response.first.staff_id).to eq(staff_id)
      expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
    end
  end

  context 'when no POMs are returned' do
    before do
      stub_poms('WEI', [])
    end

    it 'can handle no POMs for a prison' do
      response = described_class.list('WEI')

      expect(response).to be_instance_of(Array)
      expect(response.count).to eq(0)
      expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
    end
  end
end
