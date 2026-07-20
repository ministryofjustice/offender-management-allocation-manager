describe RecalculateHandoverDateJob do
  subject(:offender) { new_mpc_offender 'G1234AB' }

  let(:handover_event) { double(:handover_event) }
  let(:handover_change_event) { double(:handover_change_event) }
  let(:request_supporting_com_email) { double(:request_supporting_com_email).as_null_object }
  let(:assign_com_email) { double(:assign_com_email).as_null_object }

  before { setup_events_and_emails }

  context 'when there is no existing calculation for the offender' do
    before { the_responsibility_will_be_calculated_as(CalculatedHandoverDate.pom_only(reason: :determinate)) }

    it 'calculates and records the results' do
      created_records = CalculatedHandoverDate.where(nomis_offender_id: offender.nomis_offender_id)

      expect { recalculate_handover_dates }.to change { created_records.reload.count }.from(0).to(1)

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

    it 'does not update the record (especially running multiple times and other aspects of the offender changing)' do
      record = CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)
      expect {
        allow(offender).to receive(:attributes_to_archive).and_return({ no: 'change' })
        recalculate_handover_dates

        allow(offender).to receive(:attributes_to_archive).and_return({ some: 'change' })
        recalculate_handover_dates

        allow(offender).to receive(:attributes_to_archive).and_return({ even: 'more change' })
        recalculate_handover_dates
      }.not_to(change { record.reload.updated_at })
    end

    it 'does not emit an audit event' do
      recalculate_handover_dates
      expect(handover_change_event).not_to have_received(:publish)
    end

    it 'does not emit a handover event' do
      recalculate_handover_dates
      expect(handover_event).not_to have_received(:publish)
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

      expect { recalculate_handover_dates }.to \
        change { [record.reload.responsibility, record.reason, record.last_calculated_at] }
        .from([CalculatedHandoverDate::CUSTODY_ONLY, 'determinate', nil])
        .to([CalculatedHandoverDate::CUSTODY_WITH_COM, 'determinate_short', be_within(1.second).of(Time.zone.now)])
    end

    it 'emits an audit event for the change' do
      expect(handover_change_event).to receive(:publish).with(
        {
          nomis_offender_id: offender.nomis_offender_id,
          system_event: true,
          tags: %w[job recalculate_handover_date handover changed],
          data: {
            'before' => {
              'handover_date' => nil,
              'start_date' => nil,
              'responsibility' => CalculatedHandoverDate::CUSTODY_ONLY,
              'reason' => 'determinate',
              'last_calculated_at' => nil,
              'nomis_offender_id' => offender.nomis_offender_id,
            },
            'after' => {
              'handover_date' => Date.parse('01/01/2026'),
              'start_date' => Date.parse('01/12/2025'),
              'responsibility' => CalculatedHandoverDate::CUSTODY_WITH_COM,
              'reason' => 'determinate_short',
              'last_calculated_at' => be_within(1.second).of(Time.zone.now),
              'nomis_offender_id' => offender.nomis_offender_id,
            },
            'nomis_offender_state' => offender.attributes_to_archive
          }
        }
      )
      recalculate_handover_dates
    end
  end

  context 'when the handover date has changed' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.pom_only(reason: :determinate))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.pom_with_com(reason: :determinate_short, handover_date: 2.days.from_now))
    end

    it 'emits a handover event' do
      expect(handover_event).to receive(:publish).with(job: 'recalculate_handover_date')
      recalculate_handover_dates
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
        recalculate_handover_dates
        expect(request_supporting_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when the case has no LDU email associated' do
      before { the_case_information_is local_delivery_unit: nil }

      it 'does not send an email to the community requesting a supporting COM' do
        recalculate_handover_dates
        expect(request_supporting_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when the case has no COM allocated and has an LDU email to contact' do
      before { the_case_information_is com_email: nil, com_name: nil, local_delivery_unit: build(:local_delivery_unit, email_address: 'ldu@email.com') }

      it 'sends an email to the community to request a supporting COM' do
        recalculate_handover_dates
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
        recalculate_handover_dates
        expect(assign_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when there is already an allocated COM' do
      before { the_case_information_is com_email: 'com@email.com', com_name: 'COM User' }

      it 'does not the assign COM email' do
        recalculate_handover_dates
        expect(assign_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when the assign COM email has been sent more recently than 2 days ago' do
      before { create(:email_history, :immediate_community_allocation, nomis_offender_id: offender.nomis_offender_id) }

      it 'does not the assign COM email' do
        recalculate_handover_dates
        expect(assign_com_email).not_to have_received(:deliver_later)
      end
    end

    context 'when there is an LDU email to contact, no COM already allocated and we havent contacted in at least 2 days' do
      before { the_case_information_is com_email: nil, com_name: nil, local_delivery_unit: build(:local_delivery_unit, email_address: 'ldu@email.com') }

      it 'sends the assign COM email' do
        recalculate_handover_dates
        expect(assign_com_email).to have_received(:deliver_later)
      end
    end
  end

  context 'when the offender is outside of OMiC policy' do
    before { allow(offender).to receive(:inside_omic_policy?) }

    it 'does not send any emails' do
      recalculate_handover_dates
      expect(request_supporting_com_email).not_to have_received(:deliver_later)
      expect(assign_com_email).not_to have_received(:deliver_later)
    end

    it 'does not emit any events' do
      recalculate_handover_dates
      expect(handover_event).not_to have_received(:publish)
      expect(handover_change_event).not_to have_received(:publish)
    end

    it 'does not change any records' do
      expect { recalculate_handover_dates }.not_to(
        change { CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)&.updated_at }
      )
    end
  end

  context 'when the offender has no case information' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.com(reason: :determinate_short))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.com(reason: :determinate_short))
      CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id).destroy!
    end

    it 'does not recalculate handover dates' do
      expect { recalculate_handover_dates }.not_to(
        change { CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)&.updated_at }
      )
    end

    it 'does not send any emails' do
      recalculate_handover_dates
      expect(request_supporting_com_email).not_to have_received(:deliver_later)
      expect(assign_com_email).not_to have_received(:deliver_later)
    end

    it 'does not emit any events' do
      recalculate_handover_dates
      expect(handover_event).not_to have_received(:publish)
      expect(handover_change_event).not_to have_received(:publish)
    end
  end

  context 'when offender details are valid but case info CRN is blank' do
    before do
      the_responsibility_is_recorded_as(CalculatedHandoverDate.com(reason: :determinate_short))
      the_responsibility_will_be_calculated_as(CalculatedHandoverDate.com(reason: :determinate_short))
    end

    it 'does not send an assign COM email' do
      the_case_information_is(crn: '', local_delivery_unit: build(:local_delivery_unit, email_address: 'ldu@email.com'))
      recalculate_handover_dates
      expect(assign_com_email).not_to have_received(:deliver_later)
    end
  end

  describe 'handover checklist reset' do
    context 'when responsibility reverts to custody-only and the case leaves the window entirely' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 2.weeks.ago.to_date,
            start_date: 6.weeks.ago.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        # Recalculation moves responsibility back to custody (far future handover)
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 1.year.from_now.to_date,
            start_date: 10.months.from_now.to_date
          )
        )
      end

      it 'resets all checklist tasks to false' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true,
          attended_handover_meeting: true,
          sent_handover_report: false,
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: false,
          contacted_com: false,
          attended_handover_meeting: false,
          sent_handover_report: false,
        )
      end

      it 'creates a PaperTrail version for the reset' do
        HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        expect { recalculate_handover_dates }
          .to change { PaperTrail::Version.where(item_type: 'HandoverProgressChecklist').count }.by(1)

        version = PaperTrail::Version.where(item_type: 'HandoverProgressChecklist').last
        expect(version.whodunnit).to be_nil
      end

      it 'publishes a system audit event for the reset' do
        HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        expect(handover_change_event).to receive(:publish).with(
          hash_including(
            nomis_offender_id: offender.nomis_offender_id,
            system_event: true,
            tags: %w[record handover_progress_checklist changed]
          )
        )

        recalculate_handover_dates
      end

      it 'records as system-initiated even when triggered within a user session' do
        HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        # Simulate perform_now called from a controller action (e.g. parole review)
        PaperTrail.request.whodunnit = 'SOME_USER'

        expect(handover_change_event).to receive(:publish).with(
          hash_including(system_event: true, username: nil)
        )

        recalculate_handover_dates

        version = PaperTrail::Version.where(item_type: 'HandoverProgressChecklist').last
        expect(version.whodunnit).to be_nil
      end

      it 'does not delete the checklist record' do
        HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        expect { recalculate_handover_dates }
          .not_to change(HandoverProgressChecklist, :count)
      end
    end

    context 'when responsibility changes but the case remains in the handover window' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 3.weeks.from_now.to_date,
            start_date: 1.week.ago.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        # Recalculation moves to community responsible (in progress)
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 3.weeks.from_now.to_date,
            start_date: 1.week.ago.to_date
          )
        )
      end

      it 'does not reset checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: true,
          contacted_com: true
        )
      end
    end

    context 'when responsibility reverts to custody-only but the case lands in upcoming' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 2.weeks.ago.to_date,
            start_date: 6.weeks.ago.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        # Recalculation moves responsibility back to custody, but new handover_date is within 56 days
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 4.weeks.from_now.to_date,
            start_date: 4.weeks.from_now.to_date
          )
        )
      end

      it 'resets checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true,
          attended_handover_meeting: true,
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: false,
          contacted_com: false,
          attended_handover_meeting: false,
          sent_handover_report: false,
        )
      end
    end

    context 'when a date change moves a case in upcoming off all lists (still custody-only)' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 3.weeks.from_now.to_date,
            start_date: 3.weeks.from_now.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        # Recalculation pushes handover_date far into the future (beyond 56 days)
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 1.year.from_now.to_date,
            start_date: 10.months.from_now.to_date
          )
        )
      end

      it 'resets checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: false,
          contacted_com: false,
          attended_handover_meeting: false,
          sent_handover_report: false,
        )
      end
    end

    context 'when a date change keeps the case in upcoming (still custody-only)' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 3.weeks.from_now.to_date,
            start_date: 3.weeks.from_now.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        # Recalculation shifts handover_date slightly but still within 56 days
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 5.weeks.from_now.to_date,
            start_date: 5.weeks.from_now.to_date
          )
        )
      end

      it 'does not reset checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: true,
          contacted_com: true
        )
      end
    end

    context 'when there is no change to responsibility or handover date' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 2.weeks.ago.to_date,
            start_date: 6.weeks.ago.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 2.weeks.ago.to_date,
            start_date: 6.weeks.ago.to_date
          )
        )
      end

      it 'does not reset checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: true,
          contacted_com: true
        )
      end
    end

    context 'when in-progress and only handover_date shifts slightly (responsibility unchanged)' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 2.weeks.ago.to_date,
            start_date: 6.weeks.ago.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
            reason: :determinate,
            handover_date: 1.week.ago.to_date,
            start_date: 5.weeks.ago.to_date
          )
        )
      end

      it 'does not reset checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true,
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: true,
          contacted_com: true,
        )
      end
    end

    context 'when in upcoming and nothing changes (stable)' do
      before do
        the_responsibility_is_recorded_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 3.weeks.from_now.to_date,
            start_date: 3.weeks.from_now.to_date,
            last_calculated_at: 1.day.ago
          )
        )
        the_responsibility_will_be_calculated_as(
          CalculatedHandoverDate.new(
            responsibility: CalculatedHandoverDate::CUSTODY_ONLY,
            reason: :determinate,
            handover_date: 3.weeks.from_now.to_date,
            start_date: 3.weeks.from_now.to_date
          )
        )
      end

      it 'does not reset checklist tasks' do
        checklist = HandoverProgressChecklist.create!(
          nomis_offender_id: offender.nomis_offender_id,
          reviewed_oasys: true,
          contacted_com: true
        )

        recalculate_handover_dates

        checklist.reload
        expect(checklist).to have_attributes(
          reviewed_oasys: true,
          contacted_com: true
        )
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

  def recalculate_handover_dates
    described_class.new.perform(offender.nomis_offender_id)
  end

  def setup_events_and_emails
    # Offender
    allow(OffenderService).to receive(:get_offender)
      .with(offender.nomis_offender_id)
      .and_return(offender)

    # Handover event
    allow(handover_event).to receive(:publish)
    allow(DomainEvents::EventFactory).to receive(:build_handover_event)
      .and_return(handover_event)

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
