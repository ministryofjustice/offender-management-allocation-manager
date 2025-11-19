describe RecalculateHandoverDateJob do
  subject(:offender) { new_mpc_offender 'G1234AB' }

  let(:ndelius_event) { double(:ndelius_event) }
  let(:handover_change_event) { double(:handover_change_event) }
  let(:request_supporting_com_email) { double(:request_supporting_com_email).as_null_object }
  let(:assign_com_email) { double(:assign_com_email).as_null_object }

  before { setup_events_and_emails }

  context 'when there is no existing calculation for the offender' do
    before { the_responsibility_will_be_calculated_as(CalculatedHandoverDate.pom_only(reason: :determinate)) }

    it 'calculates and records the results' do
      created_records = CalculatedHandoverDate.where(nomis_offender_id: offender.nomis_offender_id)
      expect { recaluclate_handover_dates }.to change { created_records.reload.count }.from(0).to(1)
      expect(created_records.first.then { [it.responsibility, it.reason] }).to eq(
        [CalculatedHandoverDate::CUSTODY_ONLY, 'determinate']
      )
    end
  end

  context 'when there are no changes from the existing record' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.pom_only(reason: :determinate))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.pom_only(reason: :determinate))
    end

    it 'does not update the record' do
      record = CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)
      expect { recaluclate_handover_dates }.not_to(change { record.reload.updated_at })
    end

    it 'does not emit an audit event' do
      recaluclate_handover_dates
      expect(handover_change_event).not_to have_received(:publish)
    end

    it 'does not emit an event to NDelius' do
      recaluclate_handover_dates
      expect(ndelius_event).not_to have_received(:publish)
    end
  end

  context 'when there are changes to the existing record' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.pom_only(reason: :determinate))
      the_responsibility_will_be_calculated_as(
        CalculatedHandoverDate.pom_with_com(
          reason: :determinate_short,
          handover_date: Date.parse('01/01/2026'),
          start_date: Date.parse('01/12/2025')
        )
      )
    end

    it 'updates the record with the new details' do
      record = CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)
      expect { recaluclate_handover_dates }.to change { [record.reload.responsibility, record.reload.reason] }
        .from([CalculatedHandoverDate::CUSTODY_ONLY, 'determinate'])
        .to([CalculatedHandoverDate::CUSTODY_WITH_COM, 'determinate_short'])
    end

    it 'emits an audit event for the change' do
      expect(handover_change_event).to receive(:publish).with(
        hash_including(
          nomis_offender_id: offender.nomis_offender_id,
          system_event: true,
          tags: %w[job recalculate_handover_date handover changed],
          data: hash_including(
            'before' => hash_including(
              'handover_date' => nil,
              'start_date' => nil,
              'responsibility' => CalculatedHandoverDate::CUSTODY_ONLY,
              'reason' => 'determinate'
            ),
            'after' => hash_including(
              'handover_date' => Date.parse('01/01/2026'),
              'start_date' => Date.parse('01/12/2025'),
              'responsibility' => CalculatedHandoverDate::CUSTODY_WITH_COM,
              'reason' => 'determinate_short'
            )
          )
        )
      )
      recaluclate_handover_dates
    end
  end

  context 'when the handover date has changed' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.pom_only(reason: :determinate))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.pom_with_com(reason: :determinate_short, handover_date: 2.days.from_now))
    end

    context 'when the case information comes from nDelius' do
      before { the_case_information_is manual_entry: false }

      it 'emits an event to nDelius to inform it of a new handover date' do
        expect(ndelius_event).to receive(:publish).with(job: 'recalculate_handover_date')
        recaluclate_handover_dates
      end
    end

    context 'when the case information is manually entered' do
      before { the_case_information_is manual_entry: true }

      it 'does not emit an event to nDelius' do
        recaluclate_handover_dates
        expect(ndelius_event).not_to have_received(:publish)
      end
    end
  end

  context 'when responsibility changes from POM only to POM with COM support (ISPs)' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.pom_only(reason: :indeterminate))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.pom_with_com(reason: :indeterminate_open))
    end

    context 'when the case has a COM allocated' do
      before { the_case_information_is com_email: 'com@email.com', com_name: 'COM User' }

      it 'does not send an email to the community requesting a supporting COM' do
        recaluclate_handover_dates
        expect(request_supporting_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when the case has no LDU email associated' do
      before { the_case_information_is local_delivery_unit: nil }

      it 'does not send an email to the community requesting a supporting COM' do
        recaluclate_handover_dates
        expect(request_supporting_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when the case has no COM allocated and has an LDU email to contact' do
      before { the_case_information_is com_email: nil, com_name: nil, local_delivery_unit: build(:local_delivery_unit, email_address: 'ldu@email.com') }

      it 'sends an email to the community to request a supporting COM' do
        recaluclate_handover_dates
        expect(request_supporting_com_email).to have_received(:deliver_later)
      end
    end
  end

  context 'when responsibility is COM (determinate short)' do
    # NOTE: There is no requirement here that the responsibility has CHANGED to COM
    # Merely that it is COM now. Given that this job is run every night - this job becomes like a cron job
    # This should probably just be its own scheduled job.

    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.com(reason: :determinate_short))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.com(reason: :determinate_short))
    end

    context 'when there is no LDU email set' do
      before { the_case_information_is local_delivery_unit: nil }

      it 'does not the assign COM email' do
        recaluclate_handover_dates
        expect(assign_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when there is already an allocated COM' do
      before { the_case_information_is com_email: 'com@email.com', com_name: 'COM User' }

      it 'does not the assign COM email' do
        recaluclate_handover_dates
        expect(assign_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when the assign COM email has been sent more recently than 2 days ago' do
      before { create(:email_history, :immediate_community_allocation, nomis_offender_id: offender.nomis_offender_id) }

      it 'does not the assign COM email' do
        recaluclate_handover_dates
        expect(assign_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when there is an LDU email to contact, no COM already allocated and we havent contacted in at least 2 days' do
      before { the_case_information_is com_email: nil, com_name: nil, local_delivery_unit: build(:local_delivery_unit, email_address: 'ldu@email.com') }

      it 'sends the assign COM email' do
        recaluclate_handover_dates
        expect(assign_com_email).to have_received(:deliver_later)
      end
    end
  end

  def the_responsibility_is_recorded_as(calculated_handover_date)
    calculated_handover_date.nomis_offender_id = offender.nomis_offender_id
    calculated_handover_date.save!
  end

  def the_responsibility_will_be_calculated_as(calculated_handover_date)
    allow(HandoverDateService).to receive(:handover).and_return(calculated_handover_date)
  end

  def the_case_information_is(**args)
    CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id).update!(args)
  end

  def recaluclate_handover_dates
    described_class.new.send(:recalculate_dates_for, offender)
  end

  def setup_events_and_emails
    # Publish to NDelius event
    allow(ndelius_event).to receive(:publish)
    allow(DomainEvents::EventFactory).to receive(:build_handover_event).and_return(ndelius_event)

    # Audit Event
    stub_const('AuditEvent', handover_change_event)
    allow(handover_change_event).to receive(:publish)

    # Request Support COM email
    allow(request_supporting_com_email).to receive(:deliver_later)
    allow(CommunityMailer).to receive(:with)
      .with(hash_including(:prisoner_crn, :ldu_email))
      .and_return(request_supporting_com_email)

    # Assign COM email
    allow(assign_com_email).to receive(:deliver_later)
    allow(CommunityMailer).to receive(:with)
      .with(hash_including(:crn_number, :email))
      .and_return(assign_com_email)
  end
end
