# frozen_string_literal: true

RSpec.describe ProcessProbationUnmergeJob, type: :job do
  let(:reactivated_crn) { 'X12345' }
  let(:unmerged_crn) { 'X54321' }
  let(:event_type) { 'probation-case.unmerge.completed' }

  before do
    allow(Rails.logger).to receive(:info)
  end

  it 'is enqueued on the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  it 'delegates processing to ProbationUnmergeService#process' do
    service = instance_double(ProbationUnmergeService, process: true)

    expect(ProbationUnmergeService).to receive(:new).with(
      old_crn: reactivated_crn,
      new_crn: unmerged_crn,
      logger: anything
    ).and_return(service)

    described_class.perform_now(reactivated_crn, unmerged_crn, event_type:)

    expect(service).to have_received(:process)
  end

  it 'logs start and finish around processing' do
    service = instance_double(ProbationUnmergeService, process: true)
    allow(ProbationUnmergeService).to receive(:new).and_return(service)

    described_class.perform_now(reactivated_crn, unmerged_crn, event_type:)

    expect(Rails.logger).to have_received(:info)
      .with(/reactivated_crn=#{reactivated_crn},unmerged_crn=#{unmerged_crn}.*job=process_probation_unmerge_job,event=started/)
    expect(Rails.logger).to have_received(:info)
      .with(/reactivated_crn=#{reactivated_crn},unmerged_crn=#{unmerged_crn}.*job=process_probation_unmerge_job,event=finished/)
  end
end
