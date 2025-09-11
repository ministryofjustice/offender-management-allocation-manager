describe 'HOMD overrides responsibilities' do
  let(:prison) { create(:prison, code: 'LEI') }

  let(:homd_user) { build(:homd) }

  let(:pom) { build(:pom, firstName: 'Prison', lastName: 'Pom') }

  before do
    stub_bank_holidays
    stub_signin_spo(homd_user)
    stub_poms(prison.code, [pom, homd_user])
  end

  specify 'HOMD removes community responsibility override returning case to calculated responsibility of POM' do
    allocated_offender = build(
      :stubbed_offender,
      responsibility: :pom,
      responsibility_overridden_to: :com,
      first_name: 'Overridden',
      last_name: 'Offender',
      allocated_to: pom,
      allocated_at: prison.code
    )
    stub_offenders_for_prison(prison.code, [allocated_offender])

    visit allocated_prison_prisoners_path(prison)
    click_on 'Offender, Overridden'
    within('tr', text: 'Current responsibility Community') { click_on 'Change' }
    fill_in 'Why are you changing responsibility for this case?', with: 'Reasons are thus'
    click_on 'Confirm'

    visit allocated_prison_prisoners_path(prison)
    click_on 'Offender, Overridden'
    expect(page).to have_content('Current responsibility Custody')
  end

  specify 'HOMD overrides POM responsibility of case to community' do
    allocated_offender = build(
      :stubbed_offender,
      responsibility: :pom,
      first_name: 'Calculated',
      last_name: 'Offender',
      allocated_to: pom,
      allocated_at: prison.code
    )
    stub_offenders_for_prison(prison.code, [allocated_offender])

    visit allocated_prison_prisoners_path(prison)
    click_on 'Offender, Calculated'
    within('tr', text: 'Current responsibility Custody') { click_on 'Change' }
    choose 'The prisoner has less than 10 months less to serve'
    click_on 'Continue'
    fill_in 'Add a note to the email:', with: 'Reasons are thus'
    click_on 'Confirm'

    visit allocated_prison_prisoners_path(prison)
    click_on 'Offender, Calculated'
    expect(page).to have_content('Current responsibility Community')
  end
end
