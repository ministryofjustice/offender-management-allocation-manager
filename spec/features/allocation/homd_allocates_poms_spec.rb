describe 'HOMD allocates cases to POMS' do
  let(:prison) { create(:prison, code: 'LEI') }

  let(:offender) { build(:stubbed_offender, nomis_id: 'G1234AB', responsibility: :pom, first_name: 'Allocatable', last_name: 'Offender', tier: 'A') }

  let(:poms) do
    [
      build(:pom, :probation_officer, staffId: 1234, firstName: 'Probation', lastName: 'Pom'),
      build(:pom, :prison_officer, staffId: 9876, firstName: 'Prison', lastName: 'Pom'),
    ]
  end

  before do
    stub_bank_holidays
    stub_signin_spo(build(:homd))
    stub_poms(prison.code, poms)
    stub_offenders_for_prison(prison.code, [offender])
  end

  specify 'HOMD allocates the recommended POM to a case' do
    when_i_allocate_recommended_pom 'Probation Pom', to_case: "Offender, Allocatable"

    visit unallocated_prison_prisoners_path(prison)
    expect(page).not_to have_content('Offender, Allocatable')

    visit prison_show_pom_tab_path(prison, 1234, 'caseload')
    expect(page).to have_content('Offender, Allocatable')
  end

  specify 'HOMD overrides the recommendation and allocates a different type of POM to a case' do
    when_i_override_recommendation_and_allocate 'Prison Pom', to_case: "Offender, Allocatable", with_override_reason: 'This POM has worked with the prisoner before'

    visit unallocated_prison_prisoners_path(prison)
    expect(page).not_to have_content('Offender, Allocatable')

    visit prison_show_pom_tab_path(prison, 9876, 'caseload')
    expect(page).to have_content('Offender, Allocatable')
  end

  specify 'HOMD compares staff workloads before allocating a POM to a case' do
    alloc1 = build(:stubbed_offender, nomis_id: 'G1234XX', responsibility: :pom, tier: 'A', first_name: 'PrisPom', last_name: 'Off1')
    create(:allocation_history, nomis_offender_id: 'G1234XX', primary_pom_nomis_id: 9876, primary_pom_name: 'Prison Pom', prison: prison.code)
    alloc2 = build(:stubbed_offender, nomis_id: 'G1234YY', responsibility: :com, tier: 'B', first_name: 'PrisPom', last_name: 'Off2')
    create(:allocation_history, nomis_offender_id: 'G1234YY', primary_pom_nomis_id: 9876, primary_pom_name: 'Prison Pom', prison: prison.code)
    alloc3 = build(:stubbed_offender, nomis_id: 'G1234ZZ', responsibility: :com, tier: 'C', first_name: 'ProbPom', last_name: 'Off1')
    create(:allocation_history, nomis_offender_id: 'G1234ZZ', primary_pom_nomis_id: 1234, primary_pom_name: 'Probation Pom', prison: prison.code)
    stub_offenders_for_prison(prison.code, [offender, alloc1, alloc2, alloc3])

    visit unallocated_prison_prisoners_path(prison)
    click_on 'Offender, Allocatable'
    click_on 'Choose POM', match: :first
    find('#pom-select-1234').check
    find('#pom-select-9876').check
    click_on 'Compare workloads'

    expect(page).to have_content('Compare POMs for Allocatable Offender')

    # as we are comparing 2 POMs, the left POM will be even numbers, right will be odd numbers
    workload_data_points = all('.pom-data').map(&:text)
    expect(workload_data_points[0]).to include('Probation Pom')
    expect(workload_data_points[2]).to include('Responsible: 0 Supporting: 1 Co-working: 0')
    expect(workload_data_points[4]).to include('Tier A: 0 Tier B: 0 Tier C: 1 Tier D: 0 Tier N/A: 0')
    expect(workload_data_points[6]).to include("Current workload\n1\nallocation in last 7 days")

    expect(workload_data_points[1]).to include('Prison Pom')
    expect(workload_data_points[3]).to include('Responsible: 1 Supporting: 1 Co-working: 0')
    expect(workload_data_points[5]).to include('Tier A: 1 Tier B: 1 Tier C: 0 Tier D: 0 Tier N/A: 0')
    expect(workload_data_points[7]).to include("Current workload\n2\nallocations in last 7 days")
  end

  specify 'HOMD reallocates an allocated case' do
    create(:allocation_history, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: 9876, primary_pom_name: 'Prison Pom', prison: prison.code)

    visit allocated_prison_prisoners_path(prison)
    click_on 'Offender, Allocatable'
    within('tr', text: 'POM Prison Pom') { click_on 'Reallocate' }
    click_on 'Choose POM', match: :first
    within('tr', text: 'Probation Pom') { click_on 'Allocate' }
    click_on 'Complete allocation'

    visit prison_show_pom_tab_path(prison, 1234, 'caseload')
    expect(page).to have_content('Offender, Allocatable')
  end

  def when_i_allocate_recommended_pom(pom_name, to_case:)
    visit unallocated_prison_prisoners_path(prison)

    within('tr', text: 'G1234AB') { click_on to_case }
    click_on 'Choose POM', match: :first
    within('tr', text: pom_name) { click_on 'Allocate' }

    yield if block_given?

    click_on 'Complete allocation'
  end

  def when_i_override_recommendation_and_allocate(pom_name, to_case:, with_override_reason:)
    when_i_allocate_recommended_pom(pom_name, to_case:) do
      check with_override_reason
      click_on 'Continue'
    end
  end
end
