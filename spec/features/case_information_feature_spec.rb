describe 'case information feature' do
  context 'when doing an allocate and save' do
    let(:prison) { create(:prison) }
    let(:offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:offenders) { [offender] }
    let(:user) { build(:pom) }
    let(:rosh_level_feature_enabled) { true }

    include_context 'with missing information feature defaults'

    before do
      stub_feature_flag(:rosh_level, enabled: rosh_level_feature_enabled)
    end

    context 'when add missing details the first time (create journey)' do
      before do
        start_missing_information_journey(prison_code: prison.code, prisoner_id: offender.fetch(:prisonerNumber))
        expect_case_information_page(prison_code: prison.code, prisoner_id: offender.fetch(:prisonerNumber))
        fill_in_case_information(resourcing: 'true', tier: 'A', rosh_level: 'HIGH')
      end

      it 'allows spo to save case information and then returns to add missing info page' do
        click_button 'Save'
        expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code), ignore_query: true)
        expect(CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber)).tier).to eq('A')
        expect(CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber)).rosh_level).to eq('HIGH')
      end

      it 'allows spo to review the case after adding missing information' do
        click_button 'Save and allocate'
        expect(page).to have_current_path prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender.fetch(:prisonerNumber))
        expect(CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber)).tier).to eq('A')
        expect(CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber)).rosh_level).to eq('HIGH')
      end
    end

    context 'when updating missing information (edit journey)' do
      before do
        create(:case_information, :manual_entry, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
      end

      it 'no longer displays the save and allocate button' do
        visit edit_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        expect(page).to have_no_button('Save and allocate')
      end

      it 'requires enhanced resourcing values to be selected' do
        CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber)).update!(enhanced_resourcing: nil)
        visit edit_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        click_on 'Update'
        expect(page).to have_content('There is a problem')
        expect(page).to have_content('Select case allocation decision')
      end

      it 'shows all fields when editing a manual case' do
        visit edit_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))

        expect(page).to have_content('What is this person’s tier?')
        expect(page).to have_content('What is this person’s ROSH?')
        expect(page).to have_content('What case allocation decision has been made for this person?')
      end

      context 'when the rosh feature flag is disabled' do
        let(:rosh_level_feature_enabled) { false }

        it 'does not show the rosh field when editing a manual case' do
          visit edit_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))

          expect(page).to have_content('What is this person’s tier?')
          expect(page).to have_no_content('What is this person’s ROSH?')
          expect(page).to have_content('What case allocation decision has been made for this person?')
        end
      end
    end

    context 'when adding missing details to an imported case with some existing values' do
      before do
        create(:case_information,
               offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)),
               tier: 'A',
               rosh_level: nil,
               enhanced_resourcing: false)
      end

      it 'shows only the missing fields' do
        visit new_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))

        expect_case_information_page(
          prison_code: prison.code,
          prisoner_id: offender.fetch(:prisonerNumber),
          show_tier: false,
          show_rosh_level: true,
          show_enhanced_resourcing: false
        )
      end

      it 'fills only the missing fields and preserves existing values' do
        visit new_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))

        fill_in_case_information(rosh_level: 'HIGH')
        click_button 'Save'

        case_information = CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber))

        aggregate_failures do
          expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code), ignore_query: true)
          expect(case_information.manual_entry?).to be(true)
          expect(case_information.tier).to eq('A')
          expect(case_information.rosh_level).to eq('HIGH')
          expect(case_information.enhanced_resourcing).to be(false)
        end
      end

      context 'when more than one field is missing and validation fails' do
        before do
          CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber)).update_columns(tier: nil, rosh_level: nil)
        end

        it 'keeps the previously selected value visible on rerender' do
          visit new_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))

          fill_in_case_information(tier: 'A')
          click_button 'Save'

          aggregate_failures do
            expect(page).to have_content('There is a problem')
            expect(page).to have_content('Select ROSH')
            expect(page).to have_content('What is this person’s tier?')
            expect(page).to have_content('What is this person’s ROSH?')
            expect(page).to have_checked_field('case-information-tier-a-field', visible: :all)
          end
        end
      end
    end

    context 'when trying to edit a non manual entry' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
      end

      it 'does not allow the user to edit the case information' do
        visit edit_prison_prisoner_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        expect(page).to have_current_path('/404')
      end
    end

    context 'when the rosh feature flag is disabled' do
      let(:rosh_level_feature_enabled) { false }

      it 'allows adding missing details without showing rosh' do
        start_missing_information_journey(prison_code: prison.code, prisoner_id: offender.fetch(:prisonerNumber))

        expect_case_information_page(
          prison_code: prison.code,
          prisoner_id: offender.fetch(:prisonerNumber),
          show_rosh_level: false
        )

        fill_in_case_information(resourcing: 'true', tier: 'A')
        click_button 'Save'

        case_information = CaseInformation.find_by!(nomis_offender_id: offender.fetch(:prisonerNumber))

        aggregate_failures do
          expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code), ignore_query: true)
          expect(case_information.tier).to eq('A')
          expect(case_information.rosh_level).to be_nil
          expect(case_information.enhanced_resourcing).to be(true)
        end
      end
    end
  end
end
