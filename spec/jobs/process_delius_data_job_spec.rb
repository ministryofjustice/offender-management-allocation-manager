# frozen_string_literal: true

RSpec.describe ProcessDeliusDataJob, type: :job do
  let(:offender_id_1) { 'G4281GV' }
  let(:offender_id_2) { 'G4282GV' }
  let(:import_service) { instance_double(DeliusDataImportService) }

  before do
    allow(DeliusDataImportService).to receive(:new).and_return(import_service)
    allow(import_service).to receive(:process)
  end

  describe '#perform' do
    context 'when passed a single identifier' do
      it 'processes the identifier' do
        described_class.perform_now(offender_id_1)

        expect(import_service).to have_received(:process).with(
          offender_id_1, identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil
        )
      end
    end

    context 'when passed multiple identifiers' do
      it 'processes all identifiers' do
        described_class.perform_now([offender_id_1, offender_id_2])

        expect(import_service).to have_received(:process).with(
          offender_id_1, identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil
        )
        expect(import_service).to have_received(:process).with(
          offender_id_2, identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil
        )
      end
    end

    context 'when passed specific options' do
      it 'passes options to the service' do
        described_class.perform_now(
          offender_id_1, identifier_type: :crn, trigger_method: :event, event_type: 'foo'
        )

        expect(import_service).to have_received(:process).with(
          offender_id_1, identifier_type: :crn, trigger_method: :event, event_type: 'foo'
        )
      end
    end
  end
end
