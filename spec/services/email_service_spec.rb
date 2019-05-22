require 'rails_helper'

RSpec.describe EmailService do
  include ActiveJob::TestHelper

  let(:allocation) {
    AllocationVersion.new.tap do |a|
      a.primary_pom_nomis_id = 485_737
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
      a.primary_pom_nomis_id = 485_737
      a.nomis_offender_id = 'G2911GD'
      a.created_by_username = 'PK000223'
      a.nomis_booking_id = 0
      a.allocated_at_tier = 'A'
      a.prison = 'LEI'
      a.event = AllocationVersion::ALLOCATE_PRIMARY_POM
      a.event_trigger = AllocationVersion::USER
    }
  }

  before(:each) {
    ActiveJob::Base.queue_adapter = :test
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
  }

  it "Can send an allocation email", vcr: { cassette_name: :email_service_send_allocation_email }, versioning: true  do
    described_class.instance(allocation: allocation, message: "").send_allocation_email
    expect(enqueued_jobs.size).to eq(1)
    enqueued_jobs.clear
  end

  it "Can send a reallocation email", vcr: { cassette_name: :email_service_send_deallocation_email }, versioning: true  do
    allow(AllocationService).to receive(:get_versions_for).and_return([original_allocation])

    described_class.instance(allocation: reallocation, message: "").send_allocation_email
    expect(enqueued_jobs.size).to eq(2)
    enqueued_jobs.clear
  end
end
