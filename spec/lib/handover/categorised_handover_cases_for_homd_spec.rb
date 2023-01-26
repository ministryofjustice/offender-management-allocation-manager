RSpec.describe Handover::CategorisedHandoverCasesForHomd do
  subject(:cases_for_homd) { described_class.new(prison) }

  let(:categorised_handover_cases) do
    instance_double(Handover::CategorisedHandoverCases, upcoming: double(:upcoming_list),
                                                        in_progress: double(:in_progress_list),
                                                        overdue_tasks: double(:overdue_tasks_list),
                                                        com_allocation_overdue: double(:com_allocation_overdue_list))
  end
  let(:prison) { instance_double Prison, primary_allocated_offenders: primary_allocated_offenders }
  let(:primary_allocated_offenders) { double(:primary_allocated_offenders) }

  before do
    allow(Handover::CategorisedHandoverCases).to receive(:new).and_return(categorised_handover_cases)

    cases_for_homd # instantiate
  end

  it "builds categorised handover cases for a prison's offenders allocated a primary POM" do
    expect(Handover::CategorisedHandoverCases).to have_received(:new).with(primary_allocated_offenders)
  end

  it "delegates :upcoming to CategorisedHandoverCases component" do
    expect(cases_for_homd.upcoming).to eq categorised_handover_cases.upcoming
  end

  it "delegates :in_progress to CategorisedHandoverCases component" do
    expect(cases_for_homd.in_progress).to eq categorised_handover_cases.in_progress
  end

  it "delegates :overdue_tasks to CategorisedHandoverCases component" do
    expect(cases_for_homd.overdue_tasks).to eq categorised_handover_cases.overdue_tasks
  end

  it "delegates :com_allocation_overdue to CategorisedHandoverCases component" do
    expect(cases_for_homd.com_allocation_overdue).to eq categorised_handover_cases.com_allocation_overdue
  end
end
