RSpec.describe 'Parole set hearing outcome date', type: :feature do
  let(:pom) { build(:pom, :prison_officer) }
  let(:prison_code) { create(:prison).code }
  let(:nomis_offender) { build(:nomis_offender, prisonId: prison_code) }
  let(:offender_no) { nomis_offender.fetch(:prisonerNumber) }
  let(:offender) { create(:offender, nomis_offender_id: offender_no, case_information: build(:case_information)) }
  let!(:parole_review) { create(:parole_review, :pom_task, nomis_offender_id: offender.nomis_offender_id) }

  before do
    stub_keyworker(offender_no)
    allow_any_instance_of(MpcOffender).to receive(:mappa_details).and_return(status: :not_found)
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return(RoshSummary.missing)
    stub_signin_spo(pom, [prison_code])
    stub_onboarded_poms(prison_code, [pom])
    stub_offender(nomis_offender)

    visit prison_prisoner_path(prison_code, offender_no)
  end

  it 'has the edit link' do
    expect(page).to have_css('.moj-banner__message a',
                             text: 'Enter the date that the outcome of')
  end

  it 'links to the form' do
    click_link 'Enter the date'

    expect(page).to have_css(
      '.govuk-hint',
      text: "This is the date that PPCS sent the ‘outcome of Parole Board decision’ letter")
  end

  it 'displays an error if date is invalid' do
    click_link 'Enter the date'

    fill_in 'Day', with: '31'
    fill_in 'Month', with: '2'
    fill_in 'Year', with: '2020'

    click_button('Save')

    expect(page).to have_content('must be a valid date')
    expect(page).to have_button('Save')
    expect(page).not_to have_css('.govuk-table__cell', text: 'Mar 2020')
  end

  it 'displays on prisoner once filled' do
    click_link 'Enter the date'

    fill_in 'Day', with: '1'
    fill_in 'Month', with: '1'
    year = Time.zone.today.year - 1
    fill_in 'Year', with: year.to_s

    click_button('Save')

    expect(page).to have_current_path(prison_prisoner_review_case_details_path(prison_code, offender_no))
    expect(parole_review.reload.hearing_outcome_received_on).to eq(Date.new(year, 1, 1))
  end
end
