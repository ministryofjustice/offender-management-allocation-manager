# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NomisUserRolesService do
  let(:prison) { build(:prison) }
  let(:nomis_staff_id) { 123_456 }
  let(:pom) { build(:pom, staffId: nomis_staff_id) }
  let(:pom_list) { [pom] }

  describe '.search_staff' do
    let(:filter) { 'Smith' }
    let(:api_response) do
      {
        'content' => [
          { 'staffId' => 111 },
          { 'staffId' => 222 },
          { 'staffId' => 333 }
        ],
        'totalElements' => 3
      }
    end

    before do
      allow(HmppsApi::NomisUserRolesApi).to receive(:get_users).and_return(api_response)
      allow(prison.pom_details).to receive(:pluck).with(:nomis_staff_id).and_return([222])
    end

    it 'calls the NOMIS API with correct parameters' do
      described_class.search_staff(prison, filter)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:get_users).with(
        caseload: prison.code, filter: filter
      )
    end

    it 'filters out existing POMs and adjusts total count' do
      results, total = described_class.search_staff(prison, filter)

      expect(results).to contain_exactly({ 'staffId' => 111 }, { 'staffId' => 333 })
      expect(total).to eq(2)
    end

    context 'when API returns empty results' do
      let(:api_response) { {} }

      it 'returns empty array and zero count' do
        results, total = described_class.search_staff(prison, filter)

        expect(results).to be_empty
        expect(total).to eq(0)
      end
    end
  end

  describe '.add_pom' do
    let(:config) { { hours_per_week: 37.5 } }

    before do
      allow(HmppsApi::NomisUserRolesApi).to receive(:set_staff_role)
      allow(prison.pom_details).to receive(:create!)
    end

    it 'sets the staff role and creates POM detail' do
      described_class.add_pom(prison, nomis_staff_id, config)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:set_staff_role).with(
        prison.code, nomis_staff_id, config
      )

      expect(prison.pom_details).to have_received(:create!).with(
        nomis_staff_id: nomis_staff_id,
        status: 'active',
        hours_per_week: config[:hours_per_week]
      )
    end
  end

  describe '.remove_pom' do
    before do
      allow(prison.pom_details).to receive(:destroy_by)

      allow(AllocationHistory).to receive(:deallocate_primary_pom)
      allow(AllocationHistory).to receive(:deallocate_secondary_pom)

      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:list).and_return(pom_list)
      allow(HmppsApi::NomisUserRolesApi).to receive(:expire_staff_role)
    end

    it 'deallocates both primary and secondary POMs' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(AllocationHistory).to have_received(:deallocate_primary_pom).with(nomis_staff_id, prison.code)
      expect(AllocationHistory).to have_received(:deallocate_secondary_pom).with(nomis_staff_id, prison.code)
    end

    it 'removes the POM details' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(prison.pom_details).to have_received(:destroy_by).with(nomis_staff_id: nomis_staff_id)
    end

    it 'expires the staff role' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:expire_staff_role).with(pom)
    end

    context 'when POM is not found' do
      let(:pom_list) { [] }

      it 'does not attempt to expire the staff role' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(HmppsApi::NomisUserRolesApi).not_to have_received(:expire_staff_role)
      end
    end
  end
end
