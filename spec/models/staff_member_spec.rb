require 'rails_helper'

RSpec.describe StaffMember, type: :model do
  let(:prison) { create(:prison) }
  let(:staff_id) { 123 }
  let(:user) { described_class.new(prison, staff_id) }
  let(:offenders) do
    [
      build(:nomis_offender, prisonerNumber: 'G7514GW', prisonId: prison.code),
      build(:nomis_offender, prisonerNumber: 'G1234VV', prisonId: prison.code),
      build(:nomis_offender, prisonerNumber: 'G1234AB', prisonId: prison.code),
      build(:nomis_offender, prisonerNumber: 'G1234GG', prisonId: prison.code)
    ]
  end

  before do
    allow_any_instance_of(DomainEvents::Event).to receive(:publish).and_return(nil)
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

  describe '#unreleased_allocations' do
    let(:unreleased_offenders) { offenders }
    let(:released_offenders) do
      [
        build(:nomis_offender, prisonerNumber: 'G9991GG', prisonId: prison.code,
                               sentence: attributes_for(:sentence_detail, conditionalReleaseDate: 1.day.ago.to_date)),
        build(:nomis_offender, prisonerNumber: 'G9992GG', prisonId: prison.code,
                               sentence: attributes_for(:sentence_detail, conditionalReleaseDate: Time.zone.now.to_date))
      ]
    end

    before do
      released_offenders.each do |offender|
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
      end
      offender_without_release_date = build(:nomis_offender, prisonerNumber: 'G9592GH', prisonId: prison.code,
                                                             sentence: attributes_for(:sentence_detail, :indeterminate,
                                                                                      tariffDate: nil,
                                                                                      conditionalReleaseDate: nil,
                                                                                      releaseDate: nil))
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_without_release_date.fetch(:prisonerNumber)))
      unreleased_offenders.push(offender_without_release_date)
      all_offenders = unreleased_offenders + released_offenders

      stub_offenders_for_prison(prison.code, all_offenders)
      all_offenders.each do |offender|
        create(:allocation_history, nomis_offender_id: offender.fetch(:prisonerNumber), primary_pom_nomis_id: staff_id,
                                    prison: prison.code)
      end
    end

    it 'finds unreleased offenders without any unreleased offenders' do
      results = user.unreleased_allocations.map(&:nomis_offender_id)
      expect(results).to match_array(unreleased_offenders.map { |i| i.fetch(:prisonerNumber) })
    end
  end

  context 'when a POM has new and old allocations' do
    let(:old) { 8.days.ago }

    let(:old_primary_alloc) do
      Timecop.travel(old) do
        create(
          :allocation_history,
          primary_pom_nomis_id: staff_id,
          nomis_offender_id: 'G7514GW',
          prison: prison.code
        )
      end
    end

    let(:old_secondary_alloc) do
      Timecop.travel(old) do
        create(
          :allocation_history,
          primary_pom_nomis_id: other_staff_id,
          nomis_offender_id: 'G1234VV',
          prison: prison.code
        ).tap do |item|
          item.update!(secondary_pom_nomis_id: staff_id)
        end
      end
    end

    let(:primary_alloc) do
      create(
        :allocation_history,
        primary_pom_nomis_id: staff_id,
        nomis_offender_id: 'G1234AB',
        prison: prison.code
      )
    end

    let(:secondary_alloc) do
      create(
        :allocation_history,
        primary_pom_nomis_id: other_staff_id,
        nomis_offender_id: 'G1234GG',
        secondary_pom_nomis_id: staff_id,
        prison: prison.code
      ).tap do |item|
        item.update!(secondary_pom_nomis_id: staff_id)
      end
    end

    let!(:all_allocations) do
      [old_primary_alloc, old_secondary_alloc, primary_alloc, secondary_alloc]
    end

    let(:other_staff_id) { 485_637 }

    before do
      old_primary_alloc.update!(secondary_pom_nomis_id: other_staff_id)
    end

    it "will get allocations for a POM made within the last 7 days" do
      allocated_offenders = described_class.new(prison, staff_id).allocations.select(&:new_case?)
      expect(allocated_offenders.map(&:nomis_offender_id)).to match_array ["G1234AB", "G1234GG"]
    end
  end

  describe '#has_allocation?' do
    let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }

    before do
      allow(prison).to receive(:allocations_for_pom).with(staff_id).and_return(
        [
          double(:allocation, nomis_offender_id: nomis_offender_id),
          double(:allocation, nomis_offender_id: FactoryBot.generate(:nomis_offender_id)),
        ]
      )
    end

    it 'returns true if the given nomis_offender_id is allocated to this staff member' do
      expect(user.has_allocation?(nomis_offender_id)).to eq true
    end

    it 'returns false if the given nomis_offender_id is not allocated to this staff member' do
      expect(user.has_allocation?(FactoryBot.generate(:nomis_offender_id))).to eq false
    end
  end
end
