RSpec.describe HmppsAudit::Interaction do
  subject(:interaction) { described_class.new(what: 'VIEW_ALLOCATION', **attributes, client:) }

  let(:client) { instance_double(HmppsAudit::Client, publish: nil) }
  let(:attributes) do
    {
      who: 'user-name',
      subject_type: 'PRISONER_ID',
      subject_id: 'A1234BC',
      correlation_id: 'request-id',
      details: {},
    }
  end

  before do
    allow(Rails.error).to receive(:report)
  end

  it 'records an attempt before the operation and a success afterwards' do
    operation = double('operation')
    expect(client).to receive(:publish).with(**attributes, what: 'VIEW_ALLOCATION_ATTEMPT').ordered
    expect(operation).to receive(:call).ordered.and_return(nil)
    expect(client).to receive(:publish).with(**attributes, what: 'VIEW_ALLOCATION_SUCCESS').ordered

    interaction.record { operation.call }
  end

  it 'records a reported failure with the same context and a failureReason' do
    interaction.record { 'User does not have access to this data' }

    expect(client).to have_received(:publish).with(
      **attributes, what: 'VIEW_ALLOCATION_FAILURE',
                    details: attributes[:details].merge('failureReason' => 'User does not have access to this data')
    )
  end

  it 'records application exceptions without leaking their messages and re-raises the original' do
    error = RuntimeError.new('sensitive error message')

    expect { interaction.record { raise error } }.to(raise_error { |raised| expect(raised).to equal(error) })
    expect(client).to have_received(:publish).with(
      **attributes, what: 'VIEW_ALLOCATION_FAILURE',
                    details: attributes[:details].merge('failureReason' => 'Application failed to complete the operation: RuntimeError')
    )
  end

  it 'classifies a missing resource exception' do
    expect { interaction.record { raise ActiveRecord::RecordNotFound } }.to raise_error(ActiveRecord::RecordNotFound)
    expect(client).to have_received(:publish).with(
      **attributes, what: 'VIEW_ALLOCATION_FAILURE',
                    details: attributes[:details].merge('failureReason' => 'Resource not found')
    )
  end

  it 'executes the operation and attempts the outcome if attempt delivery fails' do
    error = IOError.new('delivery failed')
    allow(client).to receive(:publish).with(**attributes, what: 'VIEW_ALLOCATION_ATTEMPT').and_raise(error)
    operation = spy('operation', call: nil)

    interaction.record { operation.call }

    expect(operation).to have_received(:call).once
    expect(client).to have_received(:publish).with(**attributes, what: 'VIEW_ALLOCATION_SUCCESS')
    expect(Rails.error).to have_received(:report).with(
      error, handled: true, severity: :error, source: 'hmpps_audit',
             context: { what: 'VIEW_ALLOCATION_ATTEMPT', correlation_id: 'request-id' }
    )
  end

  it 'does not mislabel outcome delivery failures as application failures' do
    allow(client).to receive(:publish).with(**attributes, what: 'VIEW_ALLOCATION_SUCCESS').and_raise(IOError)

    expect { interaction.record { nil } }.not_to raise_error
    expect(client).to have_received(:publish).exactly(2).times
    expect(Rails.error).to have_received(:report).with(
      an_instance_of(IOError), handled: true, severity: :error, source: 'hmpps_audit',
                               context: { what: 'VIEW_ALLOCATION_SUCCESS', correlation_id: 'request-id' }
    )
  end

  it 'reports every failed delivery without interrupting a handled application failure' do
    allow(client).to receive(:publish).and_raise(IOError, 'delivery failed')
    operation = spy('operation', call: 'Resource not found')

    expect { interaction.record { operation.call } }.not_to raise_error

    expect(operation).to have_received(:call).once
    expect(client).to have_received(:publish).with(hash_including(what: 'VIEW_ALLOCATION_FAILURE'))
    expect(Rails.error).to have_received(:report).twice
  end

  it 'reports failure-delivery errors without masking the original application error' do
    error = RuntimeError.new('application failed')
    delivery_error = IOError.new('delivery failed')
    allow(client).to receive(:publish).with(hash_including(what: 'VIEW_ALLOCATION_FAILURE')).and_raise(delivery_error)

    expect { interaction.record { raise error } }.to(raise_error { |raised| expect(raised).to equal(error) })
    expect(Rails.error).to have_received(:report).with(
      delivery_error, handled: true, severity: :error, source: 'hmpps_audit',
                      context: { what: 'VIEW_ALLOCATION_FAILURE', correlation_id: 'request-id' }
    )
  end
end
