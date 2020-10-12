require 'rails_helper'

RSpec.describe AllocatedOffender, type: :model do
  let(:staff_id) { 1 }

  describe 'when determining what responsibility the POM has' do
    let(:offender) { build(:offender, offenderNo: 'G7514GW', latestLocationId: 'WEI', sentence: build(:sentence_detail)) }
    let(:primary_allocation) { OpenStruct.new(nomis_offender_id: 'A1111A', primary_pom_nomis_id: staff_id, prison: 'LEI') }
    let(:secondary_allocation) { OpenStruct.new(nomis_offender_id: 'B1111B', secondary_pom_nomis_id: staff_id, prison: 'LEI') }
    let(:custody_responsibility) { build(:case_information, nomis_offender_id: 'G7514GW', responsibility: build(:responsibility, nomis_offender_id: 'G7514GW', value: Responsibility::PRISON)) }
    let(:community_responsibility) { build(:case_information, nomis_offender_id: 'G7514GW', responsibility: build(:responsibility, nomis_offender_id: 'G7514GW', value: Responsibility::PROBATION)) }

    it 'will expect pom_responsibility to return the overridden supporting responsibility' do
      offender.load_case_information(community_responsibility)
      ao = described_class.new(staff_id, primary_allocation, offender)

      expect(ao.pom_responsibility).to eq('Supporting')
    end

    it 'will expect pom_responsibility to return the overridden responsible responsibility' do
      offender.load_case_information(custody_responsibility)
      ao = described_class.new(staff_id, primary_allocation, offender)

      expect(ao.pom_responsibility).to eq('Responsible')
    end

    it 'will calculate responsibility if there is no override' do
      indeterminate_offender = build(:offender,  :indeterminate, offenderNo: 'G7514GW', latestLocationId: 'WEI')
      ao = described_class.new(staff_id, primary_allocation, indeterminate_offender)
      expect(ao.pom_responsibility).to eq('Responsible')

      ao = described_class.new(staff_id, secondary_allocation, offender)
      expect(ao.pom_responsibility).to eq('Co-Working')
    end
  end
end
