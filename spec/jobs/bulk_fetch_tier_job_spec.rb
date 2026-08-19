# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkFetchTierJob, type: :job do
  it 'runs on the deferred queue' do
    expect(described_class.new.queue_name).to eq('deferred')
  end

  it 'inherits perform behaviour from FetchTierJob' do
    expect(described_class.superclass).to eq(FetchTierJob)
  end

  it 'calls TierUpdateService with bulk_refresh audit tag' do
    crn = 'X362207'
    result = TierUpdateService::Result.new(status: :unchanged, version: 3)
    allow(TierUpdateService).to receive(:call).and_return(result)

    described_class.new.perform(crn, trigger_method: :bulk_refresh)

    expect(TierUpdateService).to have_received(:call).with(crn:, audit_tags: %w[job bulk_refresh])
  end
end
