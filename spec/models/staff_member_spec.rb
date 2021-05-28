require 'rails_helper'

RSpec.describe StaffMember, type: :model do
  let(:prison) { build(:prison, code: 'LEI') }
  let(:staff_id) { 123 }
  let(:user) { described_class.new(prison, staff_id) }
  let(:offenders) {
    [
      build(:nomis_offender, offenderNo: 'G7514GW', prison_id: prison, convicted?: true, sentenced?: true,
                     indeterminate_sentence?: true, nps_case?: true, pom_supporting?: true,
                     sentence_start_date: Time.zone.today - 1.month, conditional_release_date: Time.zone.today + 12.months),
      build(:nomis_offender, offenderNo: 'G1234VV', prison_id: prison, convicted?: true, sentenced?: true,
                     nps_case?: true, pom_responsible?: true, sentence_start_date: Time.zone.today - 1.month,
                     conditional_release_date: Time.zone.today + 12.months),
      build(:nomis_offender, offenderNo: 'G1234AB', prison_id: prison, convicted?: true, sentenced?: true,
               nps_case?: true, pom_responsible?: true, sentence_start_date: Time.zone.today - 10.months,
               conditional_release_date: Time.zone.today + 2.years),
      build(:nomis_offender, offenderNo: 'G1234GG', prison_id: prison, convicted?: true, sentenced?: true,
         nps_case?: true, pom_responsible?: true, sentence_start_date: Time.zone.today - 10.months,
         conditional_release_date: Time.zone.today + 2.years)
    ]
  }

  before do
    stub_auth_token
    stub_offenders_for_prison(prison.code, offenders)
    offenders.each do |offender|
      create(:case_information, nomis_offender_id: offender.fetch(:offenderNo))
    end
  end

  context 'when checking allocations' do
    before do
      # # Allocate all of the offenders to this POM
      offenders.each do |offender|
        create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: staff_id)
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
          :allocation,
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: 'G7514GW'
        )
      end
    }

    let(:old_secondary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation,
          primary_pom_nomis_id: other_staff_id,
          nomis_offender_id: 'G1234VV',
        ).tap { |item|
          item.update!(secondary_pom_nomis_id: staff_id)
        }
      end
    }

    let(:primary_alloc) {
      create(
        :allocation,
        primary_pom_nomis_id: staff_id,
        nomis_offender_id: 'G1234AB',
      )
    }

    let(:secondary_alloc) {
      create(
        :allocation,
        primary_pom_nomis_id: other_staff_id,
        nomis_offender_id: 'G1234GG',
        secondary_pom_nomis_id: staff_id
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
