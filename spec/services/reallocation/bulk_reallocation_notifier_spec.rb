# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reallocation::BulkReallocationNotifier do
  subject(:notifier) do
    described_class.new(
      prison: prison,
      source_pom: source_pom,
      target_pom: target_pom,
      email_service: email_service,
      mailer: mailer,
    )
  end

  let(:prison) { create(:prison, code: 'LEI') }
  let(:source_pom) do
    instance_double(StaffMember, staff_id: 10_001, full_name_ordered: 'Old Pom', email_address: 'old.pom@example.com')
  end
  let(:target_pom) do
    instance_double(StaffMember, staff_id: 10_002, full_name_ordered: 'New Pom', email_address: 'new.pom@example.com')
  end
  let(:email_service) { class_double(EmailService, send_email: nil) }
  let(:mailer) { class_double(PomMailer) }
  let(:created_email) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:removed_email) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
  let(:allocation) { instance_double(AllocationHistory, primary_pom_nomis_id: target_pom.staff_id) }

  let(:reallocated_case) do
    Reallocation::BulkReallocationResult::ReallocatedCase.new(
      allocation: allocation,
      selected_case: instance_double(AllocatedOffender, full_name: 'Zephyr, Alice', nomis_offender_id: 'G1234AA'),
      further_info: { com_name: 'John Smith' },
      email_context: {
        offender_name: 'Alice Zephyr',
        prisoner_number: 'G1234AA',
        pom_role: 'Responsible'
      }
    )
  end

  let(:result) do
    Reallocation::BulkReallocationResult.new(
      source_pom_id: source_pom.staff_id,
      target_pom_id: target_pom.staff_id,
      message: 'Bulk move',
      reallocated_cases: [reallocated_case],
      remaining_cases_count: 3,
    )
  end

  it 'sends one aggregated email to the new POM and one to the old POM' do
    allow(mailer).to receive(:with).and_raise('Unexpected arguments')
    allow(mailer).to receive(:with).with(
      pom_name: 'New Pom',
      pom_email: 'new.pom@example.com',
      old_pom_name: 'Old Pom',
      message: 'Bulk move',
      allocations: ['Alice Zephyr (G1234AA) – responsible'],
      url: 'http://localhost:3000/prisons/LEI/staff/10002/caseload'
    ).and_return(instance_double(PomMailer, bulk_allocations_created: created_email))
    allow(mailer).to receive(:with).with(
      pom_name: 'Old Pom',
      pom_email: 'old.pom@example.com',
      new_pom_name: 'New Pom',
      message: 'Bulk move',
      allocations: ['Alice Zephyr (G1234AA) – responsible'],
      url: 'http://localhost:3000/prisons/LEI/staff/10001/caseload'
    ).and_return(instance_double(PomMailer, bulk_allocations_removed: removed_email))

    notifier.call(result)

    expect(email_service).to have_received(:send_email).with(
      allocation: allocation,
      message: 'Bulk move',
      pom_nomis_id: target_pom.staff_id,
      further_info: { com_name: 'John Smith' },
      notify_previous_pom: false,
    )
    expect(created_email).to have_received(:deliver_later).with(no_args)
    expect(removed_email).to have_received(:deliver_later).with(no_args)
  end

  it 'skips the new POM email when the target POM has no email address' do
    allow(target_pom).to receive(:email_address).and_return(nil)
    allow(mailer).to receive(:with).with(
      pom_name: 'Old Pom',
      pom_email: 'old.pom@example.com',
      new_pom_name: 'New Pom',
      message: 'Bulk move',
      allocations: ['Alice Zephyr (G1234AA) – responsible'],
      url: 'http://localhost:3000/prisons/LEI/staff/10001/caseload'
    ).and_return(instance_double(PomMailer, bulk_allocations_removed: removed_email))

    notifier.call(result)

    expect(mailer).not_to have_received(:with).with(hash_including(pom_email: nil))
    expect(removed_email).to have_received(:deliver_later).with(no_args)
  end

  it 'skips the old POM email when the source POM has no email address' do
    allow(source_pom).to receive(:email_address).and_return(nil)
    allow(mailer).to receive(:with).with(
      pom_name: 'New Pom',
      pom_email: 'new.pom@example.com',
      old_pom_name: 'Old Pom',
      message: 'Bulk move',
      allocations: ['Alice Zephyr (G1234AA) – responsible'],
      url: 'http://localhost:3000/prisons/LEI/staff/10002/caseload'
    ).and_return(instance_double(PomMailer, bulk_allocations_created: created_email))

    notifier.call(result)

    expect(created_email).to have_received(:deliver_later).with(no_args)
    expect(mailer).not_to have_received(:with).with(hash_including(pom_email: nil))
  end
end
