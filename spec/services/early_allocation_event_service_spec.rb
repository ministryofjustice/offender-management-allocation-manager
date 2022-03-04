require 'rails_helper'

describe EarlyAllocationEventService do
  let!(:calc_status) { create(:calculated_early_allocation_status, eligible: true) }

  before do
    # It's not easy to change the environment variable in RSpec, since it affects the entire process
    # So instead we use method sns_topic_arn as a proxy, and stub it as needed
    allow(described_class).to receive(:sns_topic_arn).and_return(env_var)
  end

  context 'when env var DOMAIN_EVENTS_TOPIC_ARN is present' do
    let(:env_var) { 'ABC123' }

    # Stub AWS SNS client
    let(:topic) { instance_double("topic") }

    it 'publishes the event' do
      allow(described_class).to receive(:sns_topic).and_return(topic)
      expect(topic).to receive(:publish).with(
        message: { offenderNo: calc_status.nomis_offender_id, eligibilityStatus: calc_status.eligible }.to_json,
        message_attributes: hash_including(
          eventType: {
            string_value: 'community-early-allocation-eligibility.status.changed',
            data_type: 'String',
          },
          version: {
            string_value: 1.to_s,
            data_type: 'Number',
          },
          detailURL: {
            string_value: "http://localhost:3000/api/offenders/#{calc_status.nomis_offender_id}",
            data_type: 'String',
          }
        )
      )

      described_class.send_early_allocation(calc_status)
    end
  end

  context 'when env var DOMAIN_EVENTS_TOPIC_ARN is missing' do
    # Environment variable is not set
    let(:env_var) { nil }

    it 'does not attempt to publish an event' do
      expect { described_class.send_early_allocation(calc_status) }.not_to raise_error
    end
  end
end
