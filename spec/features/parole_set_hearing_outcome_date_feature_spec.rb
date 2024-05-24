RSpec.describe 'Parole set hearing outcome date', type: :feature do
  let(:pom) { build(:pom, :prison_officer) }
  let(:prison_code) { create(:prison).code }
  let(:nomis_offender) { build(:nomis_offender, prisonId: prison_code) }
  let(:offender_no) { nomis_offender.fetch(:prisonerNumber) }
  let(:offender) { create(:offender, nomis_offender_id: offender_no, case_information: build(:case_information)) }
  let!(:parole_review) { create(:parole_review, :pom_task, nomis_offender_id: offender.nomis_offender_id) }

  before do
    stub_const('USE_PPUD_PAROLE_DATA', true)
    stub_keyworker(prison_code, offender_no, build(:keyworker))
    stub_signin_spo(pom, [prison_code])
    stub_poms(prison_code, [pom])
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

  it 'displays an error if date is in the future' do
    click_link 'Enter the date'

    fill_in 'Day', with: '1'
    fill_in 'Month', with: '1'
    fill_in 'Year', with: (Time.zone.today.year + 1).to_s

    click_button('Save')

    expect(page).to have_content('must be in the past')
  end

  it 'displays an error if date is incomplete' do
    click_link 'Enter the date'

    fill_in 'Day', with: '1'
    fill_in 'Month', with: '1'

    click_button('Save')

    expect(page).to have_content('and a valid date')
  end

  it 'displays on prisoner once filled' do
    click_link 'Enter the date'

    fill_in 'Day', with: '1'
    fill_in 'Month', with: '1'
    fill_in 'Year', with: '2001'

    click_button('Save')

    expect(page).to have_css('.govuk-table__cell', text: /#{parole_review.hearing_outcome}/i)
    expect(page).to have_css('.govuk-table__cell', text: 'Jan 2001')
  end
end
