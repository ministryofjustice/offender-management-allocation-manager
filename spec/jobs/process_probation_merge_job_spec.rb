# frozen_string_literal: true

RSpec.describe ProcessProbationMergeJob, type: :job do
  let(:old_crn) { 'X12345' }
  let(:new_crn) { 'X54321' }
  let(:event_type) { 'probation-case.merge.completed' }

  before do
    allow(Rails.logger).to receive(:info)
  end

  it 'is enqueued on the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  it 'delegates processing to ProbationMergeService' do
    service = instance_double(ProbationMergeService, process: true)

    expect(ProbationMergeService).to receive(:new).with(
      old_crn:,
      new_crn:,
      logger: anything
    ).and_return(service)

    described_class.perform_now(old_crn, new_crn, event_type:)

    expect(service).to have_received(:process)
  end

  it 'logs start and finish around processing' do
    service = instance_double(ProbationMergeService, process: true)
    allow(ProbationMergeService).to receive(:new).and_return(service)

    described_class.perform_now(old_crn, new_crn, event_type:)

    expect(Rails.logger).to have_received(:info)
      .with(/old_crn=#{old_crn},new_crn=#{new_crn}.*job=process_probation_merge_job,event=started/)
    expect(Rails.logger).to have_received(:info)
      .with(/old_crn=#{old_crn},new_crn=#{new_crn}.*job=process_probation_merge_job,event=finished/)
  end

  it 'discards ActiveRecord::RecordInvalid without retrying' do
    allow(ProbationMergeService).to receive(:new).and_raise(ActiveRecord::RecordInvalid.new(ProbationCaseMerge.new))

    expect { described_class.perform_now(old_crn, new_crn, event_type:) }.not_to raise_error
  end
end
