# Shitty integrated test doesn't stub out models - what can we do, short on time
RSpec.describe Handover::HandoverEmailBatchRun do
  before do
    allow(Handover::HandoverEmail).to receive(:deliver_if_deliverable)
  end

  let(:today) { Date.new(2021, 2, 12) }
  let(:allocated_to_process) do
    [
      instance_double(AllocatedOffender,
                      :to_process0,
                      offender_no: FactoryBot.generate(:nomis_offender_id),
                      first_name: 'ALI',
                      full_name_ordered: 'Ali Bloggs',
                      case_allocation: 'NPS',
                      earliest_release_2: NamedDate[Date.new(2100, 11, 12), 'UNUSED'],
                      staff_member: double(staff_id: 'STAFF1', email_address: 'staff1@example.org'),
                      allocated_com_name: 'COM 0',
                      allocated_com_email: 'com0@example.com',
                      ldu_name: 'LDU 0',
                      ldu_email_address: 'ldu0@example.com'),
      instance_double(AllocatedOffender,
                      :to_process1,
                      offender_no: FactoryBot.generate(:nomis_offender_id),
                      first_name: 'SALLY',
                      full_name_ordered: 'Sally Patel',
                      case_allocation: 'CRC',
                      earliest_release_2: NamedDate[Date.new(2200, 6, 14), 'UNUSED'],
                      staff_member: double(staff_id: 'STAFF2', email_address: 'staff2@example.org'),
                      allocated_com_name: 'COM 1',
                      allocated_com_email: 'com1@example.com',
                      ldu_name: 'LDU 1',
                      ldu_email_address: 'ldu1@example.com'),
    ]
  end

  describe '::send_all' do
    describe 'for upcoming_handover_window emails' do
      before do
        allocated_to_process.map do |offender|
          o = FactoryBot.create :offender, id: offender.offender_no
          FactoryBot.create :calculated_handover_date,
                            offender: o, handover_date: today + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION
        end
        ignored = FactoryBot.create :calculated_handover_date, handover_date: today + 1.day
        ignored_offender = instance_double(AllocatedOffender, offender_no: ignored.nomis_offender_id)

        allow(AllocatedOffender).to receive(:all).and_return(allocated_to_process + [ignored_offender])
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
            service_provider: 'NPS',
            release_date: '12 November 2100',
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
            :upcoming_handover_window, allocated_to_process[1].offender_no, 'STAFF2',
            email: 'staff2@example.org',
            full_name_ordered: 'Sally Patel',
            first_name: 'Sally',
            handover_date: '9 April 2021',
            service_provider: 'CRC',
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
            service_provider: 'NPS',
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
            service_provider: 'CRC',
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
            service_provider: 'NPS',
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
            service_provider: 'CRC',
            deliver_now: false,
          )
          expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).twice
        end
      end
    end
  end
end
