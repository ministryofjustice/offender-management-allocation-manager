describe EarlyAllocationService do
  describe '::send_early_allocation' do
    let!(:calc_status) { create(:calculated_early_allocation_status, eligible: true) }

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

  describe '::process_eligibility_change' do
    let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
    let(:offender_model) { FactoryBot.create :offender, nomis_offender_id: nomis_offender_id }
    let(:offender) do
      instance_double MpcOffender,
                      :offender,
                      model: offender_model,
                      nomis_offender_id: nomis_offender_id,
                      early_allocation?: true
    end

    before do
      allow(described_class).to receive(:send_early_allocation)
    end

    describe 'when status has never been calculated before' do
      before do
        described_class.process_eligibility_change(offender)
      end

      it 'persists early allocation eligibility status' do
        expect(offender_model.reload.calculated_early_allocation_status.eligible?).to eq true
      end

      it 'publishes event' do
        expect(described_class).to have_received(:send_early_allocation)
                                     .with(offender_model.reload.calculated_early_allocation_status)
      end
    end

    describe 'when status has changed' do
      before do
        offender_model.create_calculated_early_allocation_status!(eligible: false)
        described_class.process_eligibility_change(offender)
      end

      it 'persists early allocation eligibility status' do
        expect(offender_model.reload.calculated_early_allocation_status.eligible?).to eq true
      end

      it 'publishes event' do
        expect(described_class).to have_received(:send_early_allocation)
                                     .with(offender_model.reload.calculated_early_allocation_status)
      end
    end

    describe 'when status did not change' do
      before do
        offender_model.create_calculated_early_allocation_status!(eligible: true)
        described_class.process_eligibility_change(offender)
      end

      it 'does not publish event' do
        expect(described_class).not_to have_received(:send_early_allocation)
      end
    end
  end
end
