RSpec.describe Handover::CategorisedHandoverCasesForPom do
  subject(:cases_for_pom) { described_class.new(staff_member) }

  let(:categorised_handover_cases) do
    instance_double(Handover::CategorisedHandoverCases, upcoming: double(:upcoming_list),
                                                        in_progress: double(:in_progress_list),
                                                        overdue_tasks: double(:overdue_tasks_list),
                                                        com_allocation_overdue: double(:com_allocation_overdue_list))
  end
  let(:staff_member) { instance_double StaffMember, :staff_member, unreleased_allocations: unreleased_allocations }
  let(:unreleased_allocations) { double(:unreleased_allocations) }

  before do
    allow(Handover::CategorisedHandoverCases).to receive(:new).and_return(categorised_handover_cases)

    cases_for_pom # instantiate
  end

  it "builds categorised handover cases for a staff member's unreleased allocations" do
    expect(Handover::CategorisedHandoverCases).to have_received(:new).with(unreleased_allocations)
  end

  it "delegates :upcoming to CategorisedHandoverCases component" do
    expect(cases_for_pom.upcoming).to eq categorised_handover_cases.upcoming
  end

  it "delegates :in_progress to CategorisedHandoverCases component" do
    expect(cases_for_pom.in_progress).to eq categorised_handover_cases.in_progress
  end

  it "delegates :overdue_tasks to CategorisedHandoverCases component" do
    expect(cases_for_pom.overdue_tasks).to eq categorised_handover_cases.overdue_tasks
  end

  it "delegates :com_allocation_overdue to CategorisedHandoverCases component" do
    expect(cases_for_pom.com_allocation_overdue).to eq categorised_handover_cases.com_allocation_overdue
  end
end
