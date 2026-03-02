# frozen_string_literal: true

RSpec.describe ProcessDeliusDataJob, type: :job do
  let(:offender_id_1) { 'G4281GV' }
  let(:offender_id_2) { 'G4282GV' }
  let(:import_service) { instance_double(DeliusDataImportService, failed_identifiers: []) }

  before do
    allow(DeliusDataImportService).to receive(:new).and_return(import_service)
    allow(import_service).to receive(:process)
  end

  describe '#perform' do
    context 'when passed a single identifier' do
      it 'processes the identifier' do
        described_class.perform_now(offender_id_1)

        expect(DeliusDataImportService).to have_received(:new).with(
          identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil, logger: anything
        )
        expect(import_service).to have_received(:process).with(offender_id_1)
      end
    end

    context 'when passed multiple identifiers' do
      it 'processes all identifiers' do
        described_class.perform_now([offender_id_1, offender_id_2])

        expect(DeliusDataImportService).to have_received(:new).with(
          identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil, logger: anything
        )
        expect(import_service).to have_received(:process).with(offender_id_1)
        expect(import_service).to have_received(:process).with(offender_id_2)
      end
    end

    context 'when passed specific options' do
      it 'passes options to the service' do
        described_class.perform_now(
          offender_id_1, identifier_type: :crn, trigger_method: :event, event_type: 'foo'
        )

        expect(DeliusDataImportService).to have_received(:new).with(
          identifier_type: :crn, trigger_method: :event, event_type: 'foo', logger: anything
        )
        expect(import_service).to have_received(:process).with(offender_id_1)
      end
    end

    context 'when processing fails for some identifiers in a batch', :queueing do
      let(:import_service) { instance_double(DeliusDataImportService, failed_identifiers: [offender_id_1]) }

      it 'processes all identifiers' do
        described_class.perform_now([offender_id_1, offender_id_2])

        expect(import_service).to have_received(:process).with(offender_id_1)
        expect(import_service).to have_received(:process).with(offender_id_2)
      end

      it 're-enqueues only the failed identifiers' do
        described_class.perform_now([offender_id_1, offender_id_2])

        expect(described_class).to have_been_enqueued.with(
          [offender_id_1],
          identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil
        )
      end
    end

    context 'when processing fails for all identifiers in a batch' do
      let(:import_service) { instance_double(DeliusDataImportService, failed_identifiers: [offender_id_1, offender_id_2]) }

      it 'raises the error so Sidekiq retries the job' do
        expect {
          described_class.perform_now([offender_id_1, offender_id_2])
        }.to raise_error(RuntimeError, 'All 2 identifier(s) failed to process')
      end

      it 'does not re-enqueue a separate job', :queueing do
        expect {
          described_class.perform_now([offender_id_1, offender_id_2])
        }.to raise_error(RuntimeError)

        expect(described_class).not_to have_been_enqueued
      end
    end

    context 'when processing a single identifier fails' do
      let(:import_service) { instance_double(DeliusDataImportService, failed_identifiers: [offender_id_1]) }

      it 'raises the error so Sidekiq retries the job' do
        expect {
          described_class.perform_now(offender_id_1)
        }.to raise_error(RuntimeError, 'All 1 identifier(s) failed to process')
      end
    end
  end
end
