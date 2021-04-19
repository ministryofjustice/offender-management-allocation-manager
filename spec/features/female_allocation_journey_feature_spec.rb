# frozen_string_literal: true

require "rails_helper"

feature "womens allocation journey" do
  let(:test_strategy) { Flipflop::FeatureSet.current.test! }
  let(:prison) { build(:womens_prison) }
  let(:offenders) { build_list(:nomis_offender, 5, agencyId: 'BZI', complexityLevel: 'high') }
  let(:offender) { build(:nomis_offender, :determinate_release_in_three_years, agencyId: 'BZI') }
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

    create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: inactive_prison_pom.staff_id)
    create(:pom_detail, :part_time, prison_code: prison.code, nomis_staff_id: probation_pom.staff_id)
    create(:pom_detail, prison_code: prison.code, nomis_staff_id: probation_pom2.staff_id)

    stub_signin_spo user, [prison.code]
    stub_poms(prison.code, [probation_pom, probation_pom2, prison_pom, inactive_prison_pom])
    stub_offenders_for_prison(prison.code, offenders + [offender])

    create(:case_information, nomis_offender_id: nomis_offender_id)
    alloc = create(:allocation, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: probation_pom.staff_id)
    alloc.deallocate_offender_after_release
    alloc.update! primary_pom_nomis_id: prison_pom.staff_id
    alloc.deallocate_offender_after_release
  end

  after do
    test_strategy.switch!(:womens_estate, false)
  end

  context 'without an existing allocation' do
    before do
      # allocate some offenders to the POM so they have a case mix that looks pretty
      offenders.each_with_index do |o, index|
        ci = create(:case_information, tier: tiers[index], nomis_offender_id: o.fetch(:offenderNo))
        create(:allocation, prison: prison.code, nomis_offender_id: ci.nomis_offender_id, primary_pom_nomis_id: probation_pom.staff_id)
      end

      visit unallocated_prison_prisoners_path prison.code
      click_link 'Allocate'
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
      expect(a.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :primary_pom_allocated_at)).
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

    scenario 'rejecting recommendation' do
      find('#accordion-1-heading').click
      find('#accordion-2-heading').click

      # Choose the one non-recommended POM
      within '#accordion-1' do
        click_link 'Allocate'
      end
      # Try to just hit 'Continue' - it should bounce with a nice error
      click_button 'Continue'
      within '.govuk-error-summary' do
        expect(all('li').map(&:text)).
          to match_array(
            [
              "Select one or more reasons for not accepting the recommendation",
            ])
      end

      # now fill it in properly and continue
      find('label[for=override-override-reasons-continuity-field]').click
      click_button 'Continue'

      fill_in 'allocation-form-message-field', with: message_text
      click_button 'Complete allocation'

      a = Allocation.find_by!(nomis_offender_id: nomis_offender_id)
      expect(a.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :primary_pom_allocated_at)).
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

  context 'with an existing allocation' do
    let(:offender_id) { offenders.first.fetch(:offenderNo) }
    let(:allocation) { Allocation.find_by!(nomis_offender_id: offender_id) }

    before do
      stub_keyworker prison.code, offender_id, build(:keyworker)

      create(:case_information, tier: 'B', nomis_offender_id: offender_id)
      create(:allocation, nomis_offender_id: offender_id, prison: prison.code, primary_pom_nomis_id: probation_pom.staff_id)

      visit allocated_prison_prisoners_path prison.code
      sleep 1
      within '.allocated_offender_row_0' do
        click_link 'View'
      end
    end

    scenario 'accepting recommendation' do
      click_link 'Reallocate'

      within '#recommended_poms' do
        # there is only 1 allocation for this person, so can just click through
        click_link 'Allocate'
      end

      fill_in 'allocation-form-message-field', with: message_text
      click_button 'Complete allocation'

      expect(allocation.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :primary_pom_allocated_at)).
        to eq(message: message_text,
              allocated_at_tier: "B",
              created_by_name: " ",
              event: 'reallocate_primary_pom',
              event_trigger: "user",
              nomis_offender_id: offender_id,
              override_detail: nil,
              override_reasons: nil,
              primary_pom_name: "#{prison_pom.last_name}, #{prison_pom.first_name}",
              primary_pom_nomis_id: prison_pom.staff_id,
              prison: prison.code,
              recommended_pom_type: "prison",
              secondary_pom_name: nil,
              secondary_pom_nomis_id: nil,
              suitability_detail: nil)
    end
  end
end
