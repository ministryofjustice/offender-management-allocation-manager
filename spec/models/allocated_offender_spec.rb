require 'rails_helper'

RSpec.describe AllocatedOffender, type: :model do
  let(:staff_id) { 1 }

  describe 'when determining what responsibility the POM has' do
    let(:offender) { OpenStruct.new(offender_no: 'G7514GW', prison_id: 'WEI', convicted?: true, conditional_release_date: Time.zone.today + 10.months) }
    let(:primary_allocation) { OpenStruct.new(nomis_offender_id: 'A1111A', primary_pom_nomis_id: staff_id, prison: 'LEI') }
    let(:secondary_allocation) { OpenStruct.new(nomis_offender_id: 'B1111B', secondary_pom_nomis_id: staff_id, prison: 'LEI') }
    let(:community_responsibility) {  OpenStruct.new(nomis_offender_id: 'A1111A', value: 'Probation') }
    let(:custody_responsibility) {  OpenStruct.new(nomis_offender_id: 'A1111A', value: 'Prison') }

    it 'will expect pom_responsibility to return the overridden supporting responsibility' do
      allow(Responsibility).to receive(:find_by).and_return(community_responsibility)

      ao = described_class.new(staff_id, primary_allocation, offender)
      expect(ao.pom_responsibility).to eq('Supporting')
    end

    it 'will expect pom_responsibility to return the overridden responsible responsibility' do
      allow(Responsibility).to receive(:find_by).and_return(custody_responsibility)

      ao = described_class.new(staff_id, primary_allocation, offender)
      expect(ao.pom_responsibility).to eq('Responsible')
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
