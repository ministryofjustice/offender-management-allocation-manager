feature 'Search for offenders' do
  let(:prison_code) { 'LEI' }

  before do
    prison = create(:prison, code: prison_code)
    pom = build(:pom)

    stub_poms(prison.code, [pom])
    stub_pom_user(pom)
    stub_signin_spo(build(:homd))

    offenders = [
      build(:nomis_offender, prisonId: prison.code, prisonerNumber: 'T0000AA', firstName: 'California', lastName: 'Mccoy'),
      build(:nomis_offender, prisonId: prison.code, prisonerNumber: 'T0000AB', firstName: 'Cally', lastName: 'Agnes'),
      build(:nomis_offender, prisonId: prison.code, prisonerNumber: 'T0000AC', firstName: 'Jane', lastName: 'Doe'),
      build(:nomis_offender, prisonId: prison.code, prisonerNumber: 'T0000AD', firstName: 'Janet', lastName: 'Frank'),
      build(:nomis_offender, prisonId: prison.code, prisonerNumber: 'T0000AE', firstName: 'Bridget', lastName: 'Callins')
    ]

    offenders.each { stub_keyworker(it[:prisonerNumber]) }

    stub_offenders_for_prison(prison.code, offenders)
  end

  it 'Can search from the dashboard' do
    visit root_path
    fill_in 'Find a case', with: 'Cal'
    click_on 'Search'

    expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
    expect(all('[aria-label="Prisoner name"]').map(&:text)).to eq(['Mccoy, California T0000AA', 'Agnes, Cally T0000AB', 'Callins, Bridget T0000AE'])

    click_on 'Mccoy, California'
    expect(page).to have_title "View case information"
  end

  it 'Can search from the Allocations summary page' do
    visit allocated_prison_prisoners_path(prison_code)
    fill_in 'Find a case', with: 'Jane'
    click_on 'Search'

    expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
    expect(all('[aria-label="Prisoner name"]').map(&:text)).to eq(['Doe, Jane T0000AC', 'Frank, Janet T0000AD'])
  end

  it 'Can search from the Awaiting Allocation summary page' do
    visit unallocated_prison_prisoners_path(prison_code)
    fill_in 'Find a case', with: 'Bridget'
    click_on 'Search'

    expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
    expect(all('[aria-label="Prisoner name"]').map(&:text)).to eq(['Callins, Bridget T0000AE'])
  end

  it 'Can search from the Missing Information summary page' do
    visit missing_information_prison_prisoners_path(prison_code)
    fill_in 'Find a case', with: 'Doe'
    click_on 'Search'

    expect(page).to have_current_path(search_prison_prisoners_path(prison_code), ignore_query: true)
    expect(all('[aria-label="Prisoner name"]').map(&:text)).to eq(['Doe, Jane T0000AC'])
  end
end
