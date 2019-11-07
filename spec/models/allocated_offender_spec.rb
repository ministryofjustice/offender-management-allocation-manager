require 'rails_helper'

RSpec.describe AllocatedOffender, type: :model do
  let(:staff_id) { 1 }

  describe 'when an allocated offender may have invalid allocations' do
    let(:allocation) { OpenStruct.new(nomis_offender_id: 'G7514GW', prison: 'LEI') }

    it 'can exclude unconvicted offenders' do
      offender = OpenStruct.new(offender_no: 'G7514GW', convicted?: false)
      ao = described_class.new(staff_id, allocation, offender)

      expect(Rails.logger).to receive(:warn).with('[ALLOC] G7514GW has an allocation but is not convicted')
      expect(ao.valid?).to be false
    end

    it 'can exclude prisoners who have moved' do
      offender = OpenStruct.new(offender_no: 'G7514GW', prison_id: 'WEI', convicted?: true)
      ao = described_class.new(staff_id, allocation, offender)

      expect(Rails.logger).to receive(:warn).with('[ALLOC] G7514GW has an allocation at LEI but is at WEI')
      expect(ao.valid?).to be false
    end
  end

  describe 'when determining what responsibility the POM has' do
    let(:offender) { OpenStruct.new(offender_no: 'G7514GW', prison_id: 'WEI', convicted?: true) }
    let(:primary_allocation) { OpenStruct.new(nomis_offender_id: 'A1111A', primary_pom_nomis_id: staff_id, prison: 'LEI') }
    let(:secondary_allocation) { OpenStruct.new(nomis_offender_id: 'B1111B', secondary_pom_nomis_id: staff_id, prison: 'LEI') }
    let(:community_responsibility) {  OpenStruct.new(nomis_offender_id: 'A1111A', value: 'Probation') }

    it 'will expect pom_responsibility to return the overridden responsibility' do
      allow(Responsibility).to receive(:find_by).and_return(community_responsibility)

      ao = described_class.new(staff_id, primary_allocation, offender)
      expect(ao.pom_responsibility).to eq('Supporting')
    end

    it 'will calculate responsibility if there is no override' do
      allow(Responsibility).to receive(:find_by).and_return(nil)

      ao = described_class.new(staff_id, primary_allocation, offender)
      expect(ao.pom_responsibility).to eq('Responsible')

      ao = described_class.new(staff_id, secondary_allocation, offender)
      expect(ao.pom_responsibility).to eq('Co-Working')
    end
  end
end
