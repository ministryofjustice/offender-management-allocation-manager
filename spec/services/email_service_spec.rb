require 'rails_helper'

RSpec.describe EmailService do
  include ActiveJob::TestHelper

  let(:allocation) {
    Allocation.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'MOIC_POM'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
    end
  }

  let(:reallocation) {
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_766
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'MOIC_POM'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = Allocation::REALLOCATE_PRIMARY_POM
      a.event_trigger = Allocation::USER
    }
  }

  let(:original_allocation) {
    # The original allocation before the reallocation
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'MOIC_POM'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = Allocation::ALLOCATE_PRIMARY_POM
      a.event_trigger = Allocation::USER
    }
  }

  let(:coworking_allocation) do
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'MOIC_POM'
      a.nomis_booking_id = 0
      a.secondary_pom_nomis_id = 485_926
      a.secondary_pom_name = "Pom, Moic"
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = Allocation::ALLOCATE_SECONDARY_POM
      a.event_trigger = Allocation::USER
    }
  end

  let(:coworking_deallocation) do
    Allocation.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'MOIC_POM'
      a.nomis_booking_id = 0
      a.secondary_pom_nomis_id = nil
      a.secondary_pom_name = nil
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = Allocation::DEALLOCATE_SECONDARY_POM
      a.event_trigger = Allocation::USER
    }
  end

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  context 'when queueing', :queueing do
    it "Can send an allocation email", vcr: { cassette_name: :email_service_send_allocation_email }, versioning: true  do
      expect {
        described_class.instance(allocation: allocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(1)
    end

    it "Can not crash when a pom has no email", vcr: { cassette_name: :email_service_send_allocation_email }, versioning: true  do
      allow(PrisonOffenderManagerService).to receive(:get_pom_emails).and_return(nil)

      expect {
        described_class.instance(allocation: allocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(0)
    end

    it "Can send a reallocation email", vcr: { cassette_name: :email_service_send_deallocation_email }, versioning: true  do
      allow(AllocationService).to receive(:get_versions_for).and_return([original_allocation])

      expect {
        described_class.instance(allocation: reallocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(2)
    end

    it "Can send a co-working de-allocation email",
       vcr: { cassette_name: :email_service_send_coworking_deallocation_email }, versioning: true do
      allow(AllocationService).to receive(:get_versions_for).and_return([coworking_allocation])

      expect {
        described_class.instance(allocation: coworking_deallocation,
                                 message: "",
                                 pom_nomis_id: coworking_deallocation.primary_pom_nomis_id
        ).send_cowork_deallocation_email(coworking_allocation.secondary_pom_name)
      }.to change(enqueued_jobs, :size).by(1)
    end

    it "Can not crash when primary pom has no email when deallocating a co-working pom",
       vcr: { cassette_name: :email_service_send_coworking_deallocation_email_no_pom_email }, versioning: true do
      allow(PrisonOffenderManagerService).to receive(:get_pom_emails).and_return(nil)

      expect {
        described_class.instance(allocation: coworking_deallocation,
                                 message: "",
                                 pom_nomis_id: coworking_deallocation.primary_pom_nomis_id
        ).send_cowork_deallocation_email(coworking_allocation.secondary_pom_name)
      }.to change(enqueued_jobs, :size).by(0)
    end
  end

  context 'when offender has been released', versioning: true do
    let(:staff_id) { '485833' }
    let!(:released_allocation) do
      x = create(:allocation,
                 nomis_offender_id: original_allocation.nomis_offender_id,
                 primary_pom_nomis_id: original_allocation.primary_pom_nomis_id)
      x.deallocate_offender(Allocation::OFFENDER_RELEASED)
      x.reload
      x.update!(primary_pom_nomis_id: reallocation.primary_pom_nomis_id,
                event: Allocation::REALLOCATE_PRIMARY_POM,
                event_trigger: Allocation::USER)
      x.deallocate_offender(Allocation::OFFENDER_RELEASED)
      x.reload
      x.update!(primary_pom_nomis_id: original_allocation.primary_pom_nomis_id,
                event: Allocation::REALLOCATE_PRIMARY_POM,
                event_trigger: Allocation::USER)
      x
    end

    it "Can send a reallocation email", vcr: { cassette_name: :email_service_reallocation_crash } do
      expect(PomMailer).to receive(:deallocation_email).with(
        previous_pom_name: 'Leigh',
        responsibility: 'supporting',
        previous_pom_email: "leigh.money@digital.justice.gov.uk",
        new_pom_name: "Ricketts, Andrien",
        offender_name: "Ahmonis, Imanjah",
        offender_no: "G2911GD",
        prison: 'HMP Leeds',
        url: "http://localhost:3000/prisons/LEI/staff/#{staff_id}/caseload"
      ).and_return OpenStruct.new(deliver_later: true)

      expect(PomMailer).to receive(:new_allocation_email).with(
        pom_name: 'Andrien',
        responsibility: 'supporting',
        pom_email: 'andrien.ricketts@digital.justice.gov.uk',
        offender_name: "Ahmonis, Imanjah",
        offender_no: "G2911GD",
        message: '',
        url: "http://localhost:3000/prisons/LEI/staff/#{staff_id}/caseload"
      ).and_return OpenStruct.new(deliver_later: true)

      described_class.
        instance(allocation: released_allocation, message: "", pom_nomis_id: released_allocation.primary_pom_nomis_id).
        send_email
    end
  end
end
