require "rails_helper"

describe "HOMD views handover summary for a Prison" do
  let(:prison) { create(:prison, code: 'LEI') }

  let(:all_offenders_at_prison) do
    build_list(:nomis_offender, 2, prisonId: prison.code).tap do |offenders|
      stub_offenders_for_prison(prison.code, offenders)
    end
  end

  let(:offender_records) do
    all_offenders_at_prison.map { |offender| create(:offender, :allocatable, id: offender[:prisonerNumber]) }
  end

  let(:poms_at_prison) do
    {
      'emily' => build(:pom),
      'frank' => build(:pom)
    }.tap do |poms|
      stub_poms(prison.code, poms.values)
    end
  end

  before do
    homd = build(:pom)
    stub_signin_spo(homd)
  end

  specify 'HOMD can view upcoming handovers' do
    offender_with_upcoming_handover = offender_with_upcoming_handover(offender_records.first, allocated_to: poms_at_prison['emily'], at_prison: prison)

    visit upcoming_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Upcoming handovers (1)")
    expect(page).to have_content(offender_with_upcoming_handover.nomis_offender_id)
  end
  
  specify 'HOMD can view upcoming handovers for a POM' do
    offender_with_upcoming_handover = offender_with_upcoming_handover(offender_records.first, allocated_to: poms_at_prison['emily'], at_prison: prison)
    another_offender_with_upcoming_handover_but_different_pom = offender_with_upcoming_handover(offender_records.second, allocated_to: poms_at_prison['frank'], at_prison: prison)

    visit prison_show_pom_tab_path(prison_id: prison.code, nomis_staff_id: poms_at_prison['emily'].staffId, tab: 'handover')
    expect(page).to have_content("Upcoming handovers (1)")
    expect(page).to have_content(offender_with_upcoming_handover.nomis_offender_id)
    expect(page).not_to have_content(another_offender_with_upcoming_handover_but_different_pom.nomis_offender_id)
  end

  specify 'HOMD can view in progress handovers' do
    offender_with_in_progress_handover = offender_with_handover_in_progress(offender_records.second, allocated_to: poms_at_prison['frank'], at_prison: prison)

    visit in_progress_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Handovers in progress (1)")
    expect(page).to have_content(offender_with_in_progress_handover.nomis_offender_id)
  end

  specify 'HOMD can handovers with overdue tasks' do
    offender_with_overdue_handover_tasks = offender_with_overdue_handover_tasks(offender_records.second, allocated_to: poms_at_prison['frank'], at_prison: prison)

    visit overdue_tasks_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Handovers in progress (1)")
    expect(page).to have_content("Overdue tasks (1)")
    within 'tr', text: offender_with_overdue_handover_tasks.nomis_offender_id do
      expect(page).to have_content('Handover tasks overdue')
    end
  end

  specify 'HOMD can view handovers with com allocation overdue' do
    offender_with_com_allocation_overdue = offender_in_handover_with_com_allocation_overdue(offender_records.first, allocated_to: poms_at_prison['emily'], at_prison: prison)

    visit com_allocation_overdue_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Handovers in progress (1)")
    expect(page).to have_content("COM allocation overdue (1)")
    expect(page).to have_content(offender_with_com_allocation_overdue.nomis_offender_id)
  end
end
