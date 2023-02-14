# Shitty integrated test doesn't stub out models - what can we do, short on time
RSpec.describe Handover::HandoverEmailBatchRun do
  before do
    allow(Handover::HandoverEmail).to receive(:deliver_if_deliverable)
  end

  let(:today) { Date.new(2021, 2, 12) }

  describe "::send_all_upcoming_handover_window" do
    let(:allocated_to_process) do
      [
        instance_double(AllocatedOffender,
                        :to_process0,
                        offender_no: FactoryBot.generate(:nomis_offender_id),
                        first_name: Faker::Name.first_name,
                        full_name_ordered: Faker::Name.name,
                        case_allocation: 'NPS',
                        earliest_release_date: Date.new(2100, 11, 12),
                        staff_member: double(staff_id: 'STAFF1', email_address: 'staff1@example.org')),
        instance_double(AllocatedOffender,
                        :to_process1,
                        offender_no: FactoryBot.generate(:nomis_offender_id),
                        first_name: Faker::Name.first_name,
                        full_name_ordered: Faker::Name.name,
                        case_allocation: 'CRC',
                        earliest_release_date: Date.new(2200, 6, 14),
                        staff_member: double(staff_id: 'STAFF2', email_address: 'staff2@example.org')),
      ]
    end

    before do
      allocated_to_process.map do |offender|
        o = FactoryBot.create :offender, id: offender.offender_no
        FactoryBot.create :calculated_handover_date, offender: o,
                                                     handover_date: today + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION
      end
      ignored = FactoryBot.create :calculated_handover_date, handover_date: today + 1.day
      ignored_offender = instance_double(AllocatedOffender, offender_no: ignored.nomis_offender_id)

      allow(AllocatedOffender).to receive(:all).and_return(allocated_to_process + [ignored_offender])
    end

    it "delivers the correct cases" do
      described_class.send_all_upcoming_handover_window(for_date: today)

      aggregate_failures do
        expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
          :upcoming_handover_window, allocated_to_process[0].offender_no, 'STAFF1',
          email: 'staff1@example.org',
          full_name_ordered: allocated_to_process[0].full_name_ordered,
          first_name: allocated_to_process[0].first_name,
          handover_date: '9 Apr 2021',
          service_provider: 'NPS',
          release_date: '12 Nov 2100',
          deliver_now: false,
        )
        expect(Handover::HandoverEmail).to have_received(:deliver_if_deliverable).with(
          :upcoming_handover_window, allocated_to_process[1].offender_no, 'STAFF2',
          email: 'staff2@example.org',
          full_name_ordered: allocated_to_process[1].full_name_ordered,
          first_name: allocated_to_process[1].first_name,
          handover_date: '9 Apr 2021',
          service_provider: 'CRC',
          release_date: '14 Jun 2200',
          deliver_now: false,
        )
      end
    end
  end
end
