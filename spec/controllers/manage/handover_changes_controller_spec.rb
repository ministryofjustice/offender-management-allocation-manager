describe Manage::HandoverChangesController do
  let(:offender) { new_mpc_offender 'G1234AA' }

  before do
    allow(OffenderService).to receive(:get_offenders_in_prison)
      .with(Prison.new(code: 'LEI'))
      .and_return([offender])

    stub_sso_data('LEI', roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
  end

  describe 'viewing historic changes to the handover dates' do
    before do
      Timecop.travel(Date.parse('01/01/2025'))
      calculated_handover_date = create(
        :calculated_handover_date,
        nomis_offender_id: offender.nomis_offender_id,
        responsibility: 'CustodyWithCom',
        reason: :determinate,
        handover_date: nil,
        start_date: nil,
        last_calculated_at: Date.parse('01/01/2025')
      )

      Timecop.travel(Date.parse('20/01/2025'))
      calculated_handover_date.update(
        responsibility: 'CustodyOnly',
        reason: :determinate_short,
        handover_date: Date.parse('01/03/2025'),
        start_date: Date.parse('01/02/2025'),
        last_calculated_at: Date.parse('20/01/2025')
      )
      Timecop.return
    end

    context 'when no date is given' do
      it 'defaults to today' do
        get :historic
        expect(assigns(:selected_date)).to eq(Time.zone.today)
      end
    end

    context 'when date is given' do
      it 'sets to that date' do
        get :historic, params: { date: '10/10/2010' }
        expect(assigns(:selected_date)).to eq(Date.parse('10/10/2010'))
      end
    end

    context 'when a calculated handover date was last updated on the given date' do
      it 'returns it compared to the version before it' do
        get :historic, params: { date: '20/01/2025' }
        handover_changes = assigns(:handover_changes)
        expect(handover_changes.count).to eq(1)
        handover_change = handover_changes.first
        expect(handover_change.responsibility).to eq('CustodyWithCom')
        expect(handover_change.new_responsibility).to eq('CustodyOnly')
        expect(handover_change.reason).to eq('determinate')
        expect(handover_change.new_reason).to eq('determinate_short')
        expect(handover_change.handover_date).to eq(nil)
        expect(handover_change.new_handover_date).to eq(Date.parse('01/03/2025'))
        expect(handover_change.start_date).to eq(nil)
        expect(handover_change.new_start_date).to eq(Date.parse('01/02/2025'))
        expect(handover_change.last_calculated_at).to eq(Date.parse('01/01/2025'))
        expect(handover_change.new_last_calculated_at).to eq(Date.parse('20/01/2025'))
      end
    end

    context 'when a calculated handover date was never updated on the given date' do
      it 'returns no results' do
        get :historic, params: { date: '01/01/2025' }
        handover_changes = assigns(:handover_changes)
        expect(handover_changes.count).to eq(0)
      end
    end
  end

  describe 'viewing changes that would ocurr if handover were recalculated now' do
    before do
      create(
        :calculated_handover_date,
        nomis_offender_id: offender.nomis_offender_id,
        responsibility: 'CustodyWithCom',
        reason: :determinate,
        handover_date: nil,
        start_date: nil,
        last_calculated_at: Date.parse('01/01/2025')
      )
    end

    context 'when the handover will be calculated as different from the one stored' do
      before do
        allow(HandoverDateService).to receive(:handover)
          .with(offender)
          .and_return(
            CalculatedHandoverDate.com(
              handover_date: Date.parse('12/12/2025'),
              reason: :com_responsible
            )
          )
      end

      it 'returns the stored version compared to the live calculated version' do
        get :live
        handover_changes = assigns(:handover_changes)
        expect(handover_changes.count).to eq(1)
        handover_change = handover_changes.first
        expect(handover_change.responsibility).to eq('CustodyWithCom')
        expect(handover_change.new_responsibility).to eq('Community')
        expect(handover_change.reason).to eq('determinate')
        expect(handover_change.new_reason).to eq('com_responsible')
        expect(handover_change.handover_date).to eq(nil)
        expect(handover_change.new_handover_date).to eq(Date.parse('12/12/2025'))
        expect(handover_change.start_date).to eq(nil)
        expect(handover_change.new_start_date).to eq(nil)
        expect(handover_change.last_calculated_at).to eq(Date.parse('01/01/2025'))
        expect(handover_change.new_last_calculated_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    context 'when there is an issue calculating the live handover' do
      before { allow(HandoverDateService).to receive(:handover).and_raise }

      it 'returns nil' do
        get :live
        handover_changes = assigns(:handover_changes)
        expect(handover_changes.count).to eq(0)
      end
    end
  end
end
