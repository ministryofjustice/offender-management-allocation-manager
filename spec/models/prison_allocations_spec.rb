require 'rails_helper'

RSpec.describe Prison, type: :model do
  let(:prison) { described_class.new('LEI') }
  let(:staff_id) { 123 }
  let(:offenders) {
    [
      OpenStruct.new(offender_no: 'G7514GW', prison_id: prison, convicted?: true, sentenced?: true,
                     indeterminate_sentence?: true, nps_case?: true, pom_responsibility: 'Supporting',
                     sentence_start_date: Time.zone.today - 1.month, conditional_release_date: Time.zone.today + 12.months),
      OpenStruct.new(offender_no: 'G1234VV', prison_id: prison, convicted?: true, sentenced?: true,
                     nps_case?: true, pom_responsibility: 'Responsible', sentence_start_date: Time.zone.today - 1.month,
                     conditional_release_date: Time.zone.today + 12.months),
      OpenStruct.new(offender_no: 'G1234AB', prison_id: prison, convicted?: true, sentenced?: true,
                     nps_case?: true, pom_responsibility: 'Responsible', sentence_start_date: Time.zone.today - 10.months,
                     conditional_release_date: Time.zone.today + 2.years),
      OpenStruct.new(offender_no: 'G1234GG', prison_id: prison, convicted?: true, sentenced?: true,
                     nps_case?: true, pom_responsibility: 'Responsible', sentence_start_date: Time.zone.today - 10.months,
                     conditional_release_date: Time.zone.today + 2.years)
    ]
  }

  before do
    allow(prison).to receive(:offenders).and_return(offenders)
  end

  context 'when checking allocations' do
    before do
      # # Allocate all of the offenders to this POM
      offenders.each do |offender|
        create(:allocation, nomis_offender_id: offender.offender_no, primary_pom_nomis_id: staff_id)
      end
    end

    it 'can get the allocations for the POM at a specific prison' do
      allocations = prison.allocations_for(staff_id)
      expect(allocations.count).to eq(4)
    end

    it 'can get tasks within a caseload' do
      allocations = prison.allocations_for(staff_id)
      tasks = PomTasks.new.for_offenders(allocations.map(&:offender))
      expect(tasks.count).to eq(1)
    end

    it "will hide invalid allocations" do
      allocated_offenders = prison.allocations_for(staff_id)
      expect(allocated_offenders.count).to eq 4

      released_offender = allocated_offenders.detect { |ao| ao.offender.offender_no == 'G9999GG' }
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
          nomis_offender_id: 'G7514GW',
          nomis_booking_id: 1_153_753
        )
      end
    }

    let(:old_secondary_alloc) {
      Timecop.travel(old) do
        create(
          :allocation,
          primary_pom_nomis_id: other_staff_id,
          nomis_offender_id: 'G1234VV',
          nomis_booking_id: 971_856
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
        nomis_booking_id: 76_908
      )
    }

    let(:secondary_alloc) {
      create(
        :allocation,
        primary_pom_nomis_id: other_staff_id,
        nomis_offender_id: 'G1234GG',
        nomis_booking_id: 31_777,
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

    it "will get allocations for a POM made within the last 7 days", :versioning do
      allocated_offenders = prison.allocations_for(staff_id).select(&:new_case?)
      expect(allocated_offenders.count).to eq 2
      expect(allocated_offenders.map(&:pom_responsibility)).to match_array %w[Responsible Co-Working]
    end

    it "will get show the correct responsibility if one is overridden" do
      # Find a responsible offender
      allocated_offenders = prison.allocations_for(staff_id)
      responsible_pom = allocated_offenders.detect { |offender| offender.pom_responsibility == 'Responsible' }.offender

      # Override their responsibility
      create(:responsibility, nomis_offender_id: responsible_pom.offender_no)

      # Confirm that the responsible offender is now supporting
      allocated_offenders = prison.allocations_for(staff_id)
      responsible_pom = allocated_offenders.detect { |a| a.offender.offender_no == responsible_pom.offender_no }
      expect(responsible_pom.pom_responsibility).to eq('Supporting')
    end

    it "will get show the correct responsibility if one is overridden to probation" do
      # Find a responsible offender
      allocated_offenders = prison.allocations_for(staff_id)
      responsible_pom = allocated_offenders.detect { |offender| offender.pom_responsibility == 'Responsible' }.offender

      # Override their responsibility
      create(:responsibility, nomis_offender_id: responsible_pom.offender_no, value: 'Probation')

      # Confirm that the responsible offender is now supporting
      allocated_offenders = prison.allocations_for(staff_id)
      responsible_pom = allocated_offenders.detect { |a| a.offender.offender_no == responsible_pom.offender_no }
      expect(responsible_pom.pom_responsibility).to eq('Supporting')
    end
  end
end
