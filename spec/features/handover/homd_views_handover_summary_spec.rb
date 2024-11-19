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
    offender_with_upcoming_handover = offender_records.first
    create(:allocation_history, primary_pom_nomis_id: poms_at_prison['emily'].staffId, prison: prison.code, offender: offender_with_upcoming_handover)
    create(:calculated_handover_date, :upcoming_handover, offender: offender_with_upcoming_handover)

    visit upcoming_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Upcoming handovers (1)")
    expect(page).to have_content(offender_with_upcoming_handover.nomis_offender_id)
  end

  specify 'HOMD can view in progress handovers' do
    offender_with_in_progress_handover = offender_records.second
    create(:allocation_history, primary_pom_nomis_id: poms_at_prison['frank'].staffId, prison: prison.code, offender: offender_with_in_progress_handover)
    create(:calculated_handover_date, :handover_in_progress, offender: offender_with_in_progress_handover)

    visit in_progress_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Handovers in progress (1)")
    expect(page).to have_content(offender_with_in_progress_handover.nomis_offender_id)
  end

  specify 'HOMD can handovers with overdue tasks' do
    offender_with_overdue_handover_tasks = offender_records.second
    create(:allocation_history, primary_pom_nomis_id: poms_at_prison['frank'].staffId, prison: prison.code, offender: offender_with_overdue_handover_tasks)
    create(:calculated_handover_date, :handover_in_progress, offender: offender_with_overdue_handover_tasks)
    # ensure offender has standard handover - contacted_com is a required task for standard handover
    offender_with_overdue_handover_tasks.case_information.update!(enhanced_resourcing: false)
    create(:handover_progress_checklist, contacted_com: false, offender: offender_with_overdue_handover_tasks)

    visit overdue_tasks_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Handovers in progress (1)")
    expect(page).to have_content("Overdue tasks (1)")
    within 'tr', text: offender_with_overdue_handover_tasks.nomis_offender_id do
      expect(page).to have_content('Handover tasks overdue')
    end
  end

  specify 'HOMD can view handovers with com allocation overdue' do
    offender_with_com_allocation_overdue = offender_records.first
    create(:allocation_history, primary_pom_nomis_id: poms_at_prison['emily'].staffId, prison: prison.code, offender: offender_with_com_allocation_overdue)
    create(:calculated_handover_date, :handover_in_progress, offender: offender_with_com_allocation_overdue)
    offender_with_com_allocation_overdue.case_information.update!(com_email: nil, com_name: nil)

    visit com_allocation_overdue_prison_handovers_path(prison_id: prison.code)
    expect(page).to have_content("Handovers in progress (1)")
    expect(page).to have_content("COM allocation overdue (1)")
    expect(page).to have_content(offender_with_com_allocation_overdue.nomis_offender_id)
  end
end
