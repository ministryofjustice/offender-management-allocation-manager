describe 'case information feature' do
  context 'when doing an allocate and save' do
    let(:prison) { create(:prison) }
    let(:offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:spo) { build(:pom) }

    before do
      stub_signin_spo(spo, [prison.code])
      stub_offenders_for_prison(prison.code, [offender])
      stub_poms(prison.code, [spo])
    end

    context 'when add missing details the first time (create journey)' do
      before do
        visit new_prison_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        find('label[for=case-information-enhanced-resourcing-true-field]').click
        find('label[for=case-information-tier-a-field]').click
      end

      it 'allows spo to save case information and then returns to add missing info page' do
        click_button 'Save'
        expect(page).to have_current_path(missing_information_prison_prisoners_path(prison.code), ignore_query: true)
        expect(CaseInformation.find_by(nomis_offender_id: offender.fetch(:prisonerNumber)).tier).to eq('A')
      end

      it 'allows spo to redirect to allocation page after adding missing information' do
        click_button 'Save and allocate'
        expect(page).to have_current_path prison_prisoner_staff_index_path(prison.code, offender.fetch(:prisonerNumber))
        expect(CaseInformation.find_by(nomis_offender_id: offender.fetch(:prisonerNumber)).tier).to eq('A')
      end
    end

    context 'when updating missing information (edit journey)' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
      end

      it 'no longer displays the save and allocate button' do
        visit edit_prison_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        expect(page).to have_no_button('Save and allocate')
      end

      it 'requires enhanced resourcing values to be selected' do
        CaseInformation.find_by(nomis_offender_id: offender.fetch(:prisonerNumber)).update(enhanced_resourcing: nil)
        visit edit_prison_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        click_on 'Update'
        expect(page).to have_content('There is a problem')
        expect(page).to have_content('Select the handover type for this case')
      end
    end

    context 'when trying to edit a non manual entry' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)), manual_entry: false)
      end

      it 'does not allow the user to edit the case information' do
        visit edit_prison_case_information_path(prison.code, offender.fetch(:prisonerNumber))
        expect(page).to have_current_path('/404')
      end
    end
  end
end
