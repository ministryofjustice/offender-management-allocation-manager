# frozen_string_literal: true

RSpec.describe ProcessPrisonerMergeJob, type: :job do
  let(:old_id) { 'A3646EA' }
  let(:new_id) { 'A3645EA' }
  let(:event_type) { 'prison-offender-events.prisoner.merged' }

  before do
    allow(Rails.logger).to receive(:info)
  end

  it 'is enqueued on the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  it 'delegates processing to PrisonerMergeService' do
    service = instance_double(PrisonerMergeService, process: true)

    expect(PrisonerMergeService).to receive(:new).with(
      old_offender_id: old_id,
      new_offender_id: new_id,
      logger: anything
    ).and_return(service)

    described_class.perform_now(old_id, new_id, event_type:)

    expect(service).to have_received(:process)
  end

  it 'logs start and finish around processing' do
    service = instance_double(PrisonerMergeService, process: true)
    allow(PrisonerMergeService).to receive(:new).and_return(service)

    described_class.perform_now(old_id, new_id, event_type:)

    expect(Rails.logger).to have_received(:info)
      .with(/old_offender_id=#{old_id},new_offender_id=#{new_id}.*job=process_prisoner_merge_job,event=started/)
    expect(Rails.logger).to have_received(:info)
      .with(/old_offender_id=#{old_id},new_offender_id=#{new_id}.*job=process_prisoner_merge_job,event=finished/)
  end
end
