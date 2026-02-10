# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NomisUserRolesService do
  let(:prison) { build(:prison) }
  let(:nomis_staff_id) { 123_456 }
  let(:spo_username) { 'SPO_USER' }
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
      allow(prison).to receive(:get_list_of_poms).and_return([double(staff_id: 222)])
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
    let(:pom_detail) { instance_double(PomDetail) }

    before do
      allow(HmppsApi::NomisUserRolesApi).to receive(:set_staff_role)
      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:expire_list_cache)
      allow(prison.pom_details).to receive(:find_or_initialize_by).with(nomis_staff_id:).and_return(pom_detail)
      allow(pom_detail).to receive(:update!)
    end

    it 'sets the staff role and creates or updates the POM details' do
      described_class.add_pom(prison, nomis_staff_id, spo_username, config)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:set_staff_role).with(
        prison.code, nomis_staff_id, config
      )

      expect(
        HmppsApi::PrisonApi::PrisonOffenderManagerApi
      ).to have_received(:expire_list_cache).with(prison.code)

      expect(prison.pom_details).to have_received(:find_or_initialize_by).with(nomis_staff_id:)
      expect(pom_detail).to have_received(:update!).with(
        created_by: spo_username,
        status: 'active',
        hours_per_week: config[:hours_per_week]
      )
    end
  end

  describe '.remove_pom' do
    let(:event_trigger) { AllocationHistory::INACTIVE_POM }

    before do
      allow(prison.pom_details).to receive(:destroy_by)

      allow(AllocationHistory).to receive(:deallocate_primary_pom)
      allow(AllocationHistory).to receive(:deallocate_secondary_pom)

      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:list).and_return(pom_list)
      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:expire_list_cache)
      allow(HmppsApi::NomisUserRolesApi).to receive(:expire_staff_role)
    end

    it 'deallocates both primary and secondary POMs' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(AllocationHistory).to have_received(:deallocate_primary_pom).with(
        nomis_staff_id, prison.code, event_trigger:
      )
      expect(AllocationHistory).to have_received(:deallocate_secondary_pom).with(
        nomis_staff_id, prison.code, event_trigger:
      )
    end

    it 'removes the POM details' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(prison.pom_details).to have_received(:destroy_by).with(nomis_staff_id: nomis_staff_id)
    end

    it 'expires the staff role' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:expire_staff_role).with(pom)

      expect(
        HmppsApi::PrisonApi::PrisonOffenderManagerApi
      ).to have_received(:expire_list_cache).with(prison.code)
    end

    context 'when POM is not found' do
      let(:pom_list) { [] }

      it 'does not attempt to expire the staff role' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(HmppsApi::NomisUserRolesApi).not_to have_received(:expire_staff_role)
        expect(HmppsApi::PrisonApi::PrisonOffenderManagerApi).not_to have_received(:expire_list_cache)
      end
    end
  end
end
