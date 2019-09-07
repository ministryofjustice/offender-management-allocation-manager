require 'rails_helper'

describe POMService::GetAllocatedOffenders do
  let(:staff_id) { 485_737 }
  let(:other_staff_id) { 485_637 }

  before(:each) {
    PomDetail.create(nomis_staff_id: :other_staff_id, working_pattern: 1.0, status: 'inactive')
  }

  describe '#get_allocated_offenders' do
    let(:old) { 8.days.ago }

    let(:old_primary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation_version,
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: 'G4273GI',
          nomis_booking_id: 1_153_753
        )
      end
    }

    let(:old_secondary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation_version,
          primary_pom_nomis_id: other_staff_id,
          nomis_offender_id: 'G8060UF',
          nomis_booking_id: 971_856
        ).tap { |item|
          item.update!(secondary_pom_nomis_id: staff_id)
        }
      end
    }

    let(:primary_alloc) {
      create(
        :allocation_version,
        primary_pom_nomis_id: staff_id,
        nomis_offender_id: 'G8624GK',
        nomis_booking_id: 76_908
      )
    }

    let(:secondary_alloc) {
      create(
        :allocation_version,
        primary_pom_nomis_id: other_staff_id,
        nomis_offender_id: 'G1714GU',
        nomis_booking_id: 31_777
      ).tap { |item|
        item.update!(secondary_pom_nomis_id: staff_id)
      }
    }

    let!(:all_allocations) {
      [old_primary_alloc, old_secondary_alloc, primary_alloc, secondary_alloc]
    }

    before do
      old_primary_alloc.update!(secondary_pom_nomis_id: other_staff_id)
    end

    it "will get allocations for a POM made within the last 7 days", :versioning, vcr: { cassette_name: :get_new_cases } do
      allocated_offenders = described_class.call(staff_id, 'LEI').
        select(&:new_case?)
      expect(allocated_offenders.count).to eq 2
      expect(allocated_offenders.map(&:responsibility)).to match_array [ResponsibilityService::SUPPORTING, 'Co-Working']
    end
  end
end
