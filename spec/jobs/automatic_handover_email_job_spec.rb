RSpec.describe AutomaticHandoverEmailJob, type: :job do
  before do
    allow(Prison).to receive(:active).and_return(prisons)
  end

  let(:prison) { double(Prison, code: prison_code, name: 'Liecester') }
  let(:prisons) { [prison] }
  let(:prison_code) { 'LEI' }

  describe '#filter_offenders' do
    subject(:filtered) do
      described_class.new.send(:filter_offenders, mpc_offenders,
                               run_on: run_on, last_report_on: last_report_on)
    end

    let(:run_on) { Date.new(2020, 1, 15) }
    let(:last_report_on) { Date.new(2020, 1, 1) }

    context 'with a handover within the send window' do
      let(:mpc_offenders) do
        [
          double(MpcOffender, prison_id: prison_code, sentenced?: true,
                              handover_start_date: run_on + 1,
                              handover_last_calculated_at: nil),
          double(MpcOffender, prison_id: prison_code, sentenced?: true,
                              handover_start_date: run_on + described_class::SEND_THRESHOLD + 1,
                              handover_last_calculated_at: nil)
        ]
      end

      it 'finds the handover' do
        expect(filtered).to eq([mpc_offenders.first])
      end
    end

    context 'with a handover that would have been missed off last report' do
      let(:mpc_offenders) do
        [
          double(MpcOffender, prison_id: prison_code, sentenced?: true,
                              handover_start_date: run_on - 1,
                              handover_last_calculated_at: last_report_on + 1),
          double(MpcOffender, prison_id: prison_code, sentenced?: true,
                              handover_start_date: run_on - 1,
                              handover_last_calculated_at: nil),
          double(MpcOffender, prison_id: prison_code, sentenced?: true,
                              handover_start_date: run_on - 1,
                              handover_last_calculated_at: last_report_on - 1)
        ]
      end

      it 'finds the handover' do
        expect(filtered).to eq([mpc_offenders.first])
      end
    end
  end

  describe '#perform' do
    before do
      allow_any_instance_of(described_class).to receive(:get_ldu_offenders).and_return(mpc_offenders)
      allow(CommunityMailer).to receive(:with).and_return(mailer)
      allow(Prison).to receive(:find).and_return(prison)

      described_class.perform_now(ldu)
    end

    let(:ldu) { double(LocalDeliveryUnit, name: 'X', email_address: 'x@x.com', code: 'X') }
    let(:mail_instance) { double(deliver_now: nil) }

    let(:mailer) do
      double(pipeline_to_community: mail_instance,
             pipeline_to_community_no_handovers: mail_instance)
    end

    context 'when it finds LDU offenders and there are handovers' do
      let(:mpc_offenders) do
        [
          double(MpcOffender, prison_id: prison_code, sentenced?: true,
                              full_name: 'Fred',
                              crn: '123',
                              offender_no: 'AB000C',
                              allocated_com_name: 'Bob',
                              conditional_release_date: nil,
                              parole_eligibility_date: nil,
                              tariff_date: Time.zone.today + 700,
                              handover_date: Time.zone.today + 1,
                              handover_start_date: Time.zone.today + 1,
                              handover_last_calculated_at: nil)
        ]
      end

      it 'sends email with CSV' do
        expect(CommunityMailer).to have_received(:with)
          .with(ldu:, csv_data: anything)
      end
    end

    context 'when it finds LDU offenders but none are handovers' do
      let(:mpc_offenders) do
        [double(MpcOffender, prison_id: prison_code, sentenced?: false)]
      end

      it 'sends email without CSV' do
        expect(CommunityMailer).to have_received(:with).with(ldu:)
      end
    end

    context 'when the LDU is empty with no offenders' do
      let(:mpc_offenders) { [] }

      it 'sends no email' do
        expect(CommunityMailer).not_to have_received(:with)
      end
    end
  end
end
