# frozen_string_literal: true

require "rails_helper"

feature "womens allocation journey" do
  let(:test_strategy) { Flipflop::FeatureSet.current.test! }
  let(:prison) { build(:womens_prison) }
  let(:offenders) { build_list(:nomis_offender, 5, complexityLevel: 'high') }
  let(:offender) { build(:nomis_offender) }
  let(:nomis_offender_id) { offender.fetch(:offenderNo) }
  let(:user) { build(:pom) }
  let(:probation_pom) { build(:pom, :probation_officer) }
  let(:probation_pom2) { build(:pom, :probation_officer) }
  let(:inactive_prison_pom) { build(:pom, :prison_officer) }
  let(:prison_pom) { build(:pom, :prison_officer) }
  let(:message_text) { Faker::Lorem.sentence }
  let(:tiers) { ['A', 'B', 'C', 'D', 'N/A'].cycle.take(offenders.size) }

  before do
    test_strategy.switch!(:womens_estate, true)

    create(:pom_detail, :inactive, nomis_staff_id: inactive_prison_pom.staff_id)
    create(:pom_detail, :part_time, nomis_staff_id: probation_pom.staff_id)
    create(:pom_detail, nomis_staff_id: probation_pom2.staff_id)

    stub_signin_spo user, [prison.code]
    stub_poms(prison.code, [probation_pom, probation_pom2, prison_pom, inactive_prison_pom])
    stub_offenders_for_prison(prison.code, offenders + [offender])

    offenders.each_with_index do |o, index|
      ci = create(:case_information, tier: tiers[index], nomis_offender_id: o.fetch(:offenderNo))
      create(:allocation, prison: prison.code, nomis_offender_id: ci.nomis_offender_id, primary_pom_nomis_id: probation_pom.staff_id)
    end

    create(:case_information, nomis_offender_id: nomis_offender_id)
    alloc = create(:allocation, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: probation_pom.staff_id)
    alloc.deallocate_offender_after_release
    alloc.update! primary_pom_nomis_id: prison_pom.staff_id
    alloc.deallocate_offender_after_release

    visit unallocated_prison_prisoners_path prison.code
    click_link 'Allocate'
    # visit new_prison_prisoner_allocation_path(prison.code, nomis_offender_id)
  end

  after do
    test_strategy.switch!(:womens_estate, false)
  end

  scenario 'accepting recommendation' do
    within '#recommended_poms' do
      # allocate to the second person in the list
      within 'tr:nth-of-type(2)' do
        click_link 'Allocate'
      end
    end
    fill_in 'allocation-form-message-field', with: message_text
    click_button 'Complete allocation'
    a = Allocation.find_by!(nomis_offender_id: nomis_offender_id)
    expect(a.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :nomis_booking_id, :primary_pom_allocated_at)).
      to eq(message: message_text,
            allocated_at_tier: "A",
            created_by_name: " ",
            event: 'allocate_primary_pom',
            event_trigger: "user",
            nomis_offender_id: nomis_offender_id,
            override_detail: nil,
            override_reasons: nil,
            primary_pom_name: "#{probation_pom2.last_name}, #{probation_pom2.first_name}",
            primary_pom_nomis_id: probation_pom2.staff_id,
            prison: prison.code,
            recommended_pom_type: "probation",
            secondary_pom_name: nil,
            secondary_pom_nomis_id: nil,
            suitability_detail: nil)
  end

  scenario 'rejecting recommendation', :js do
    sleep 2
    find('#accordion-1-heading').click
    find('#accordion-2-heading').click
    sleep 3
    within '#accordion-1' do
      click_link 'Allocate'
    end
    sleep 2
    click_button 'Continue'
    sleep 4
    find('label[for=override-override-reasons-continuity-field]').click
    click_button 'Continue'
    sleep 5
    fill_in 'allocation-form-message-field', with: message_text
    click_button 'Complete allocation'
    a = Allocation.find_by!(nomis_offender_id: nomis_offender_id)
    expect(a.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :nomis_booking_id, :primary_pom_allocated_at)).
      to eq(message: message_text,
            allocated_at_tier: "A",
            created_by_name: " ",
            event: 'allocate_primary_pom',
            event_trigger: "user",
            nomis_offender_id: nomis_offender_id,
            override_detail: '',
            override_reasons: "[\"continuity\"]",
            primary_pom_name: "#{prison_pom.last_name}, #{prison_pom.first_name}",
            primary_pom_nomis_id: prison_pom.staff_id,
            prison: prison.code,
            recommended_pom_type: "probation",
            secondary_pom_name: nil,
            secondary_pom_nomis_id: nil,
            suitability_detail: '')
  end
end
