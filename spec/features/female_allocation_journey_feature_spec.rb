# frozen_string_literal: true

require "rails_helper"

feature "womens allocation journey" do
  let(:prison) { create(:womens_prison) }
  let(:offenders) { build_list(:nomis_offender, 5, prisonId: prison.code, complexityLevel: 'high') }
  let(:offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, :determinate_release_in_three_years), prisonId: prison.code) }
  let(:offender_name) { "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}" }
  let(:nomis_offender_id) { offender.fetch(:prisonerNumber) }
  let(:user) { build(:pom) }
  let(:probation_pom) { build(:pom, :probation_officer, lastName: 'Jones') }
  # This has to be alphabetically after probation_pom so it turns up in the right place on the screen
  let(:probation_pom2) { build(:pom, :probation_officer, lastName: 'Smith') }
  let(:inactive_prison_pom) { build(:pom, :prison_officer) }
  let(:prison_pom) { build(:pom, :prison_officer) }
  let(:message_text) { Faker::Lorem.sentence }
  let(:tiers) { ['A', 'B', 'C', 'D', 'N/A'].cycle.take(offenders.size) }

  before do
    create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: inactive_prison_pom.staff_id)
    create(:pom_detail, :part_time, prison_code: prison.code, nomis_staff_id: probation_pom.staff_id)
    create(:pom_detail, prison_code: prison.code, nomis_staff_id: probation_pom2.staff_id)

    stub_signin_spo user, [prison.code]
    stub_poms(prison.code, [probation_pom, probation_pom2, prison_pom, inactive_prison_pom])
    stub_filtered_pom(prison.code, probation_pom)
    stub_filtered_pom(prison.code, probation_pom2)
    stub_filtered_pom(prison.code, prison_pom)
    stub_offenders_for_prison(prison.code, offenders + [offender])

    create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
    alloc = create(:allocation_history, prison: prison.code, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: probation_pom.staff_id)
    alloc.deallocate_offender_after_release
    alloc.update! primary_pom_nomis_id: prison_pom.staff_id
    alloc.deallocate_offender_after_release

    stub_bank_holidays
    stub_community_offender(nomis_offender_id, build(:community_data))
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return({ status: :missing })
  end

  context 'without an existing allocation' do
    before do
      # allocate some offenders to the POM so they have a case mix that looks pretty
      offenders.each_with_index do |o, index|
        ci = create(:case_information, tier: tiers[index], offender: build(:offender, nomis_offender_id: o.fetch(:prisonerNumber)))
        create(:allocation_history, prison: prison.code, nomis_offender_id: ci.nomis_offender_id, primary_pom_nomis_id: probation_pom.staff_id)
      end

      stub_keyworker(prison.code, offender[:prisonerNumber], build(:keyworker))

      visit unallocated_prison_prisoners_path prison.code
      click_link offender_name
      # Now on Review case page

      click_link 'Choose a POM to allocate to now'
      # Now on 'Choose a POM' page
    end

    scenario 'accepting recommendation' do
      within "tr#pom-#{probation_pom2.staffId}" do
        # allocate to the second person in the list
        click_link 'Allocate'
      end

      fill_in 'allocation-form-message-field', with: message_text
      click_button 'Complete allocation'
      a = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id)
      expect(a.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :primary_pom_allocated_at))
        .to eq(message: message_text,
               allocated_at_tier: "A",
               created_by_name: "MOIC POM",
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
      # Choose the one non-recommended POM
      within "tr#pom-#{prison_pom.staffId}" do
        click_link 'Allocate'
      end

      # Try to just hit 'Continue' - it should bounce with a nice error
      click_button 'Continue'
      within '.govuk-error-summary' do
        expect(all('li').map(&:text))
          .to match_array(
            [
              "Select one or more reasons for not accepting the recommendation",
            ])
      end

      # now fill it in properly and continue
      find('label[for=override-form-override-reasons-continuity-field]').click
      click_button 'Continue'

      fill_in 'allocation-form-message-field', with: message_text
      click_button 'Complete allocation'

      a = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id)
      expect(a.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :primary_pom_allocated_at))
        .to eq(message: message_text,
               allocated_at_tier: "A",
               created_by_name: "MOIC POM",
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
    let(:offender_id) { offenders.first.fetch(:prisonerNumber) }
    let(:offender_name) { "#{offenders.first.fetch(:lastName)}, #{offenders.first.fetch(:firstName)}" }
    let(:allocation) { AllocationHistory.find_by!(nomis_offender_id: offender_id) }

    before do
      stub_keyworker prison.code, offender_id, build(:keyworker)

      create(:case_information, tier: 'C', offender: build(:offender, nomis_offender_id: offender_id))
      create(:allocation_history, nomis_offender_id: offender_id, prison: prison.code, primary_pom_nomis_id: probation_pom.staff_id)

      visit allocated_prison_prisoners_path prison.code
      sleep 1
      within '.allocated_offender_row_0' do
        click_link offender_name
      end
      # Now on allocation page

      stub_community_offender(offender_id, build(:community_data))
    end

    scenario 'accepting recommendation' do
      click_link 'Reallocate'
      # Now on Review case page

      click_link 'Choose a POM to allocate to now'

      within "tr#pom-#{prison_pom.staffId}" do
        click_link 'Allocate'
      end

      fill_in 'allocation-form-message-field', with: message_text
      click_button 'Complete allocation'

      expect(allocation.attributes.symbolize_keys.except(:created_at, :updated_at, :id, :primary_pom_allocated_at))
        .to eq(message: message_text,
               allocated_at_tier: "C",
               created_by_name: "MOIC POM",
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
