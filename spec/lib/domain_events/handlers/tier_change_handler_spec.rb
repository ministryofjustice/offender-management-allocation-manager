RSpec.describe DomainEvents::Handlers::TierChangeHandler do
  subject!(:handler) { described_class.new }

  let(:crn) { 'X408769' }
  let(:event) do
    DomainEvents::Event.new(
      event_type: 'tier.calculation.changed',
      version: event_version,
      description: 'Tier calculation changed',
      detail_url: "https://hmpps-tier.example.org/crn/#{crn}/tier/#{calculation_id}",
      additional_information: { 'calculationId' => calculation_id },
      crn_number: crn,
      external_event: true
    )
  end
  let(:tier_from_api) { 'D1' }
  let(:calculation_id) { 'a5e7d3c1-9b4f-4e2a-8c6d-1f3b5a7e9d02' }
  let(:event_version) { 3 }

  before do
    allow(Shoryuken::Logging.logger).to receive(:info).and_return(nil)
    allow(Shoryuken::Logging.logger).to receive(:error).and_return(nil)
    allow(AuditEvent).to receive(:publish).and_return(nil)
    allow(HmppsApi::TieringApi).to receive(:get_calculation)
      .with(crn, calculation_id, version: event_version)
      .and_return({ tier: tier_from_api })
  end

  context 'when local case information found' do
    let!(:case_information) { create(:case_information, crn: crn, tier: tier) }
    let(:tier) { 'A' }

    before { handler.handle(event) }

    it 'passes crn, calculationId, and version to TieringApi' do
      expect(HmppsApi::TieringApi).to have_received(:get_calculation)
        .with(crn, calculation_id, version: event_version)
    end

    context 'when tier has not changed' do
      let(:tier) { 'D' }

      it 'does not update the record' do
        expect(case_information.reload.tier).to eq('D')
      end

      it 'emits no audit event' do
        expect(AuditEvent).not_to have_received(:publish)
      end
    end

    context 'when case information update successful' do
      it 'updates tier with first char of new value' do
        expect(case_information.reload.tier).to eq('D')
      end

      it 'sets manual_entry to false' do
        expect(case_information.reload.manual_entry).to be(false)
      end

      it 'emits a log info message' do
        expect(Shoryuken::Logging.logger).to have_received(:info).at_least(2).times
      end

      it 'emits an audit event with before and after state' do
        expect(AuditEvent).to have_received(:publish).once.with(
          nomis_offender_id: case_information.nomis_offender_id,
          tags: %w[handler case_information tier changed],
          system_event: true,
          data: {
            'before' => { 'tier' => 'A' },
            'after' => { 'tier' => 'D' }
          }
        )
      end

      context 'when manual_entry was true' do
        let!(:case_information) { create(:case_information, :manual_entry, crn: crn, tier: tier) }

        it 'sets manual_entry to false' do
          expect(case_information.reload.manual_entry).to be(false)
        end

        it 'includes manual_entry in the audit event' do
          expect(AuditEvent).to have_received(:publish).once.with(
            nomis_offender_id: case_information.nomis_offender_id,
            tags: %w[handler case_information tier changed],
            system_event: true,
            data: {
              'before' => { 'tier' => 'A', 'manual_entry' => true },
              'after' => { 'tier' => 'D', 'manual_entry' => false }
            }
          )
        end
      end
    end

    context 'when case information update not successful' do
      let(:tier_from_api) { 'Z1' }

      it 'emits a log error message' do
        expect(Shoryuken::Logging.logger).to have_received(:error).once
      end
    end
  end

  context 'when tiering API returns an error' do
    let!(:case_information) { create(:case_information, crn: crn, tier: 'A') }
    let(:tier_from_api) { nil }

    before { handler.handle(event) }

    it 'does not update tier' do
      expect(case_information.reload.tier).to eq('A')
    end

    it 'emits no audit event' do
      expect(AuditEvent).not_to have_received(:publish)
    end
  end
end
