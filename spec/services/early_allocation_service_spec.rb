describe EarlyAllocationService do
  let!(:calc_status) { create(:calculated_early_allocation_status, eligible: true) }

  # Stub AWS SNS client
  let(:topic) { instance_double("topic") }

  before do
    allow(described_class).to receive(:sns_topic).and_return(topic)
  end

  it 'publishes the event' do
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
