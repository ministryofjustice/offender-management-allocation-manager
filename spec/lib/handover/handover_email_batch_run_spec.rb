RSpec.describe Handover::HandoverEmailBatchRun do
  let(:today) { Date.new(2021, 2, 12) }
  let(:allocated_to_process) do
    [
      instance_double(AllocatedOffender,
                      :to_process0,
                      offender_no: FactoryBot.generate(:nomis_offender_id),
                      first_name: 'ALI',
                      full_name_ordered: 'Ali Bloggs',
                      enhanced_handover?: true,
                      staff_member: double(staff_id: 'STAFF1', email_address: 'staff1@example.org'),
                      allocated_com_name: 'COM 0',
                      allocated_com_email: 'com0@example.com',
                      ldu_name: 'LDU 0',
                      ldu_email_address: 'ldu0@example.com',
                      earliest_release_for_handover: NamedDate[Date.new(2100, 11, 12), 'UNUSED']),
      instance_double(AllocatedOffender,
                      :to_process1,
                      offender_no: FactoryBot.generate(:nomis_offender_id),
                      first_name: 'SALLY',
                      full_name_ordered: 'Sally Patel',
                      enhanced_handover?: false,
                      staff_member: double(staff_id: 'STAFF2', email_address: 'staff2@example.org'),
                      allocated_com_name: 'COM 1',
                      allocated_com_email: 'com1@example.com',
                      ldu_name: 'LDU 1',
                      ldu_email_address: 'ldu1@example.com',
                      earliest_release_for_handover: NamedDate[Date.new(2200, 6, 14), 'UNUSED'])
    ]
  end

  before do
    allow(Handover::HandoverEmail).to receive(:deliver_if_deliverable)
  end

  describe '::send_all' do
    describe 'for upcoming_handover_window emails' do
      before do
        allocated_to_process.map do |offender|
          o = FactoryBot.create :offender, id: offender.offender_no
          FactoryBot.create :calculated_handover_date, offender: o, handover_date: today + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION
        end
        ignored = []

        ignored1 = FactoryBot.create :calculated_handover_date, handover_date: today + 1.day
        ignored.push instance_double(AllocatedOffender, offender_no: ignored1.nomis_offender_id)

        ignored.push instance_double(AllocatedOffender, offender_no: 'NO_CHD', has_com?: true)

        allow(AllocatedOffender).to receive(:all).and_return(allocated_to_process + ignored)
      end

      it "delivers the correct cases" do
        described_class.send_all(for_date: today)

        aggregate_failures do
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :upcoming_handover_window, allocated_to_process[0].offender_no, 'STAFF1',
            email: 'staff1@example.org',
            full_name_ordered: 'Ali Bloggs',
            first_name: 'Ali',
            handover_date: '9 April 2021',
            enhanced_handover: true,
            release_date: '12 November 2100',
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :upcoming_handover_window, allocated_to_process[1].offender_no, 'STAFF2',
            email: 'staff2@example.org',
            full_name_ordered: 'Sally Patel',
            first_name: 'Sally',
            handover_date: '9 April 2021',
            enhanced_handover: false,
            release_date: '14 June 2200',
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).twice
        end
      end
    end

    describe 'for handover_date emails' do
      before do
        allocated_to_process.map do |offender|
          allow(offender).to receive_messages(has_com?: true)
          o = FactoryBot.create :offender, id: offender.offender_no
          FactoryBot.create :calculated_handover_date, offender: o, handover_date: today
        end
        ignored = []

        ignored1 = FactoryBot.create :calculated_handover_date, handover_date: today + 1.day
        ignored.push instance_double(AllocatedOffender, offender_no: ignored1.offender.id, has_com?: true)

        ignored2 = FactoryBot.create :calculated_handover_date, handover_date: today - 1.day
        ignored.push instance_double(AllocatedOffender, offender_no: ignored2.offender.id, has_com?: true)

        ignored_no_com = FactoryBot.create :calculated_handover_date, handover_date: today
        ignored.push instance_double(AllocatedOffender, offender_no: ignored_no_com.offender.id, has_com?: false)

        ignored.push instance_double(AllocatedOffender, offender_no: 'NO_CHD', has_com?: true)

        allow(AllocatedOffender).to receive(:all).and_return(allocated_to_process + ignored)
      end

      it "delivers the correct cases" do
        described_class.send_all(for_date: today)

        aggregate_failures do
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :handover_date, allocated_to_process[0].offender_no, 'STAFF1',
            email: 'staff1@example.org',
            full_name_ordered: 'Ali Bloggs',
            first_name: 'Ali',
            release_date: '12 November 2100',
            com_name: 'COM 0',
            com_email: 'com0@example.com',
            enhanced_handover: true,
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :handover_date, allocated_to_process[1].offender_no, 'STAFF2',
            email: 'staff2@example.org',
            full_name_ordered: 'Sally Patel',
            first_name: 'Sally',
            release_date: '14 June 2200',
            com_name: 'COM 1',
            com_email: 'com1@example.com',
            enhanced_handover: false,
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).twice
        end
      end
    end

    describe 'for com_allocation_overdue emails' do
      before do
        allocated_to_process.map do |offender|
          allow(offender).to receive_messages(has_com?: false)
          o = FactoryBot.create :offender, id: offender.offender_no
          FactoryBot.create :calculated_handover_date, offender: o, handover_date: today - 14.days
        end
        ignored = []

        ignored1 = FactoryBot.create :calculated_handover_date, handover_date: today + 1.day
        ignored.push instance_double(AllocatedOffender, offender_no: ignored1.offender.id, has_com?: false)

        ignored2 = FactoryBot.create :calculated_handover_date, handover_date: today + 1.day
        ignored.push instance_double(AllocatedOffender, offender_no: ignored2.offender.id, has_com?: false)

        ignored_has_com = FactoryBot.create :calculated_handover_date, handover_date: today - 14.days
        ignored.push instance_double(AllocatedOffender, offender_no: ignored_has_com.offender.id, has_com?: true)

        ignored.push instance_double(AllocatedOffender, offender_no: 'NO_CHD', has_com?: true)

        allow(AllocatedOffender).to receive(:all).and_return(allocated_to_process + ignored)
      end

      it "delivers the correct cases" do
        described_class.send_all(for_date: today)

        aggregate_failures do
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :com_allocation_overdue, allocated_to_process[0].offender_no, 'STAFF1',
            email: 'staff1@example.org',
            full_name_ordered: 'Ali Bloggs',
            release_date: '12 November 2100',
            handover_date: '29 January 2021',
            ldu_name: 'LDU 0',
            ldu_email: 'ldu0@example.com',
            enhanced_handover: true,
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :com_allocation_overdue, allocated_to_process[1].offender_no, 'STAFF2',
            email: 'staff2@example.org',
            full_name_ordered: 'Sally Patel',
            release_date: '14 June 2200',
            handover_date: '29 January 2021',
            ldu_name: 'LDU 1',
            ldu_email: 'ldu1@example.com',
            enhanced_handover: false,
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).twice
        end
      end
    end
  end

  describe 'error handling' do
    let(:retryable_error_classes) do
      [
        HandoverMailer::InvalidRecipientEmailError,
        ActiveJob::EnqueueError,
        ActiveRecord::ConnectionTimeoutError,
        ActiveRecord::Deadlocked,
      ]
    end
    let(:offender) do
      instance_double(AllocatedOffender,
                      offender_no: FactoryBot.generate(:nomis_offender_id),
                      first_name: 'ALI',
                      full_name_ordered: 'Ali Bloggs',
                      enhanced_handover?: true,
                      staff_member: double(staff_id: 'STAFF1', email_address: nil),
                      has_com?: true,
                      allocated_com_name: 'COM 0',
                      allocated_com_email: 'com0@example.com',
                      ldu_name: 'LDU 0',
                      ldu_email_address: 'ldu0@example.com',
                      earliest_release_for_handover: NamedDate[Date.new(2100, 11, 12), 'UNUSED'])
    end

    before do
      o = FactoryBot.create :offender, id: offender.offender_no
      FactoryBot.create :calculated_handover_date, offender: o, handover_date: today + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION
      allow(AllocatedOffender).to receive(:all).and_return([offender])
    end

    it 're-raises allowlisted retryable errors so the batch can be retried' do
      allow(Rails.logger).to receive(:error)

      retryable_error_classes.each do |error_class|
        allow(Handover::HandoverEmail).to receive(:deliver_if_deliverable)
          .and_raise(error_class, 'retry me')

        expect {
          described_class.send_all(for_date: today)
        }.to raise_error(error_class)
      end

      expect(Rails.logger).to have_received(:error)
        .with(include('event=handover_email_batch_run_error'))
        .exactly(retryable_error_classes.size).times
    end

    it 'logs and continues for unrelated errors' do
      allow(Handover::HandoverEmail).to receive(:deliver_if_deliverable).and_raise(StandardError, 'boom')
      allow(Rails.logger).to receive(:error)

      expect {
        described_class.send_all(for_date: today)
      }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(include('event=handover_email_batch_run_error'))
    end
  end

  describe 'when a reminder was already sent in an earlier attempt' do
    let(:offender) do
      instance_double(AllocatedOffender,
                      offender_no: FactoryBot.generate(:nomis_offender_id),
                      first_name: 'ALI',
                      full_name_ordered: 'Ali Bloggs',
                      enhanced_handover?: true,
                      staff_member: double(staff_id: 'STAFF1', email_address: 'staff1@example.org'),
                      has_com?: true,
                      allocated_com_name: 'COM 0',
                      allocated_com_email: 'com0@example.com',
                      ldu_name: 'LDU 0',
                      ldu_email_address: 'ldu0@example.com',
                      earliest_release_for_handover: NamedDate[Date.new(2100, 11, 12), 'UNUSED'])
    end

    before do
      o = FactoryBot.create :offender, id: offender.offender_no
      FactoryBot.create :calculated_handover_date, offender: o, handover_date: today + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION
      allow(AllocatedOffender).to receive(:all).and_return([offender])
      allow(Handover::HandoverEmail).to receive(:deliver_if_deliverable).and_return(false)
      allow(Rails.logger).to receive(:info)
    end

    it 'does not log the reminder as delivered again' do
      described_class.send_all(for_date: today)

      expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
        :upcoming_handover_window, offender.offender_no, 'STAFF1',
        email: 'staff1@example.org',
        full_name_ordered: 'Ali Bloggs',
        first_name: 'Ali',
        handover_date: '9 April 2021',
        enhanced_handover: true,
        release_date: '12 November 2100',
        deliver_now: false,
      )
      expect(Rails.logger).not_to have_received(:info).with(include('event=handover_email_delivered'))
    end
  end
end
