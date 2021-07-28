require 'rails_helper'

RSpec.describe StaffMember, type: :model do
  let(:prison) { create(:prison) }
  let(:staff_id) { 123 }
  let(:user) { described_class.new(prison, staff_id) }
  let(:offenders) {
    [
      build(:nomis_offender, prisonerNumber: 'G7514GW', prisonId: prison.code),
      build(:nomis_offender, prisonerNumber: 'G1234VV', prisonId: prison.code),
      build(:nomis_offender, prisonerNumber: 'G1234AB', prisonId: prison.code),
      build(:nomis_offender, prisonerNumber: 'G1234GG', prisonId: prison.code)
    ]
  }

  before do
    stub_auth_token
    stub_offenders_for_prison(prison.code, offenders)
    offenders.each do |offender|
      create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
    end
  end

  context 'when checking allocations' do
    before do
      # # Allocate all of the offenders to this POM
      offenders.each do |offender|
        create(:allocation_history, nomis_offender_id: offender.fetch(:prisonerNumber), primary_pom_nomis_id: staff_id, prison: prison.code)
      end
    end

    let(:allocations) { user.allocations }

    it 'can get the allocations for the POM at a specific prison' do
      expect(allocations.count).to eq(4)
    end

    it "will hide invalid allocations" do
      released_offender = allocations.detect { |ao| ao.offender_no == 'G9999GG' }
      expect(released_offender).to be_nil
    end
  end

  context 'when a POM has new and old allocations' do
    let(:old) { 8.days.ago }

    let(:old_primary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation_history,
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: 'G7514GW',
          prison: prison.code
        )
      end
    }

    let(:old_secondary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation_history,
          primary_pom_nomis_id: other_staff_id,
          nomis_offender_id: 'G1234VV',
          prison: prison.code
        ).tap { |item|
          item.update!(secondary_pom_nomis_id: staff_id)
        }
      end
    }

    let(:primary_alloc) {
      create(
        :allocation_history,
        primary_pom_nomis_id: staff_id,
        nomis_offender_id: 'G1234AB',
        prison: prison.code
      )
    }

    let(:secondary_alloc) {
      create(
        :allocation_history,
        primary_pom_nomis_id: other_staff_id,
        nomis_offender_id: 'G1234GG',
        secondary_pom_nomis_id: staff_id,
        prison: prison.code
      ).tap { |item|
        item.update!(secondary_pom_nomis_id: staff_id)
      }
    }

    let!(:all_allocations) {
      [old_primary_alloc, old_secondary_alloc, primary_alloc, secondary_alloc]
    }

    let(:other_staff_id) { 485_637 }

    before do
      old_primary_alloc.update!(secondary_pom_nomis_id: other_staff_id)
    end

    it "will get allocations for a POM made within the last 7 days" do
      allocated_offenders = described_class.new(prison, staff_id).allocations.select(&:new_case?)
      expect(allocated_offenders.map(&:nomis_offender_id)).to match_array ["G1234AB", "G1234GG"]
    end
  end
end
