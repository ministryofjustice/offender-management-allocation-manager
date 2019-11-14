require 'rails_helper'

RSpec.describe EmailService, :queueing do
  include ActiveJob::TestHelper

  let(:allocation) {
    AllocationVersion.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'PK000223'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
    end
  }

  let(:reallocation) {
    AllocationVersion.new.tap { |a|
      a.primary_pom_nomis_id = 485_766
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'PK000223'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = AllocationVersion::REALLOCATE_PRIMARY_POM
      a.event_trigger = AllocationVersion::USER
    }
  }

  let(:original_allocation) {
    # The original allocation before the reallocation
    AllocationVersion.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'PK000223'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = AllocationVersion::ALLOCATE_PRIMARY_POM
      a.event_trigger = AllocationVersion::USER
    }
  }

  let(:coworking_allocation) do
    AllocationVersion.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'PK000223'
      a.nomis_booking_id = 0
      a.secondary_pom_nomis_id = 485_752
      a.secondary_pom_name = "Jones, Ross"
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = AllocationVersion::ALLOCATE_SECONDARY_POM
      a.event_trigger = AllocationVersion::USER
    }
  end

  let(:coworking_deallocation) do
    AllocationVersion.new.tap { |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'PK000223'
      a.nomis_booking_id = 0
      a.secondary_pom_nomis_id = nil
      a.secondary_pom_name = nil
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = AllocationVersion::DEALLOCATE_SECONDARY_POM
      a.event_trigger = AllocationVersion::USER
    }
  end

  before(:each) {
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

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

  context 'when offender has been released', versioning: true do
    let!(:released_allocation) do
      x = create(:allocation_version,
                 nomis_offender_id: original_allocation.nomis_offender_id,
                 primary_pom_nomis_id: original_allocation.primary_pom_nomis_id)
      x.deallocate_offender(AllocationVersion::OFFENDER_RELEASED)
      x.reload
      x.update!(primary_pom_nomis_id: reallocation.primary_pom_nomis_id,
                event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                event_trigger: AllocationVersion::USER)
      x.deallocate_offender(AllocationVersion::OFFENDER_RELEASED)
      x.reload
      x.update!(primary_pom_nomis_id: original_allocation.primary_pom_nomis_id,
                event: AllocationVersion::REALLOCATE_PRIMARY_POM,
                event_trigger: AllocationVersion::USER)
      x
    end

    it "Can send a reallocation email", vcr: { cassette_name: :email_service_reallocation_crash } do
      expect {
        described_class.instance(allocation: released_allocation, message: "", pom_nomis_id: released_allocation.primary_pom_nomis_id).send_email
      }.to change(enqueued_jobs, :size).by(2)
      # POM 485_833 is Andrien
      expect(enqueued_jobs.last[:args][3]['pom_email']).to eq("andrien.ricketts@digital.justice.gov.uk")
    end
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
