require 'rails_helper'

RSpec.describe EmailService do
  include ActiveJob::TestHelper

  let(:allocation) do
    AllocationHistory.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.allocated_at_tier = 'A'
      a.prison = prison_code
    end
  end

  let(:reallocation) do
    AllocationHistory.new.tap do |a|
      a.primary_pom_nomis_id = 485_766
      a.nomis_offender_id = 'G2911GD'
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = AllocationHistory::REALLOCATE_PRIMARY_POM
      a.event_trigger = AllocationHistory::USER
    end
  end

  let(:original_allocation) do
    # The original allocation before the reallocation
    AllocationHistory.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.nomis_offender_id = 'G2911GD'
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = AllocationHistory::ALLOCATE_PRIMARY_POM
      a.event_trigger = AllocationHistory::USER
    end
  end

  let(:coworking_allocation) do
    AllocationHistory.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.secondary_pom_nomis_id = 485_926
      a.secondary_pom_name = "Pom, Moic"
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = AllocationHistory::ALLOCATE_SECONDARY_POM
      a.event_trigger = AllocationHistory::USER
    end
  end

  let(:coworking_deallocation) do
    AllocationHistory.new.tap do |a|
      a.primary_pom_nomis_id = 485_833
      a.primary_pom_name = "Ricketts, Andrien"
      a.nomis_offender_id = 'G2911GD'
      a.secondary_pom_nomis_id = nil
      a.secondary_pom_name = nil
      a.allocated_at_tier = 'A'
      a.prison = prison_code
      a.event = AllocationHistory::DEALLOCATE_SECONDARY_POM
      a.event_trigger = AllocationHistory::USER
    end
  end

  let(:andrien) { build(:pom, staffId: 485_833) }
  let(:leigh) { build(:pom, staffId: 485_766) }
  let(:offender) { build(:nomis_offender, prisonId: prison_code, prisonerNumber: 'G2911GD') }
  let(:prison) { create(:prison) }
  let(:prison_code) { prison.code }
  let(:offender_name) { "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}" }

  before do
    PomDetail.create(nomis_staff_id: 485_637, working_pattern: 1.0, status: 'inactive')
    create(:case_information, offender: build(:offender, nomis_offender_id: 'G2911GD'))
    stub_offender(offender)
    stub_poms(prison_code, [andrien, leigh])
    stub_filtered_pom(prison_code, andrien)
  end

  context 'when queueing', :queueing do
    it "Can send an allocation email"  do
      expect {
        described_class.send_email(allocation: allocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id)
      }.to change(enqueued_jobs, :size).by(1)
    end

    it "Can not crash when a pom has no email"  do
      allow(HmppsApi::NomisUserRolesApi).to receive(:email_address).and_return(nil)

      expect {
        described_class.send_email(allocation: allocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id)
      }.not_to change(enqueued_jobs, :size)
    end

    it "Can send a reallocation email"  do
      allow(reallocation).to receive(:get_old_versions).and_return([original_allocation])

      expect {
        described_class.send_email(allocation: reallocation, message: "", pom_nomis_id: allocation.primary_pom_nomis_id)
      }.to change(enqueued_jobs, :size).by(2)
    end

    it "Can send a co-working de-allocation email" do
      allow(original_allocation).to receive(:get_old_versions).and_return([coworking_allocation])

      expect {
        described_class.send_cowork_deallocation_email(allocation: coworking_deallocation, pom_nomis_id: coworking_deallocation.primary_pom_nomis_id, secondary_pom_name: coworking_allocation.secondary_pom_name)
      }.to change(enqueued_jobs, :size).by(1)
    end

    it "Can not crash when primary pom has no email when deallocating a co-working pom" do
      allow(HmppsApi::NomisUserRolesApi).to receive(:email_address).and_return(nil)

      expect {
        described_class.send_cowork_deallocation_email(allocation: coworking_deallocation,
                                                       pom_nomis_id: coworking_deallocation.primary_pom_nomis_id,
                                                       secondary_pom_name: coworking_allocation.secondary_pom_name)
      }.not_to change(enqueued_jobs, :size)
    end
  end

  context 'when offender has been released' do
    let(:staff_id) { '485833' }
    let!(:released_allocation) do
      create(:allocation_history,
             prison: prison_code,
             nomis_offender_id: original_allocation.nomis_offender_id,
             primary_pom_nomis_id: original_allocation.primary_pom_nomis_id).tap do |x|
        x.deallocate_offender_after_release
        x.reload
        x.update!(primary_pom_nomis_id: reallocation.primary_pom_nomis_id,
                  event: AllocationHistory::REALLOCATE_PRIMARY_POM,
                  event_trigger: AllocationHistory::USER)
        x.deallocate_offender_after_release
        x.reload
        x.update!(primary_pom_nomis_id: original_allocation.primary_pom_nomis_id,
                  event: AllocationHistory::REALLOCATE_PRIMARY_POM,
                  event_trigger: AllocationHistory::USER)
      end
    end

    it "Can send a reallocation email", :aggregate_failures do
      deallocation_email = double(:deallocation_email, deliver_later: nil)
      new_allocation_email = double(:new_allocation_email, deliver_later: nil)

      allow(PomMailer).to receive(:with).and_raise('Unexpected arguments')
      allow(PomMailer).to receive(:with).with(
        previous_pom_name: leigh.first_name,
        responsibility: 'responsible',
        previous_pom_email: leigh.email_address,
        new_pom_name: "#{andrien.last_name}, #{andrien.first_name}",
        offender_name: offender_name,
        offender_no: "G2911GD",
        prison: prison.name,
        further_info: {},
        url: "http://localhost:3000/prisons/#{prison_code}/staff/#{staff_id}/caseload"
      ).and_return(double(deallocation_email: deallocation_email))

      allow(PomMailer).to receive(:with).with(
        pom_name: andrien.first_name,
        responsibility: 'responsible',
        pom_email: andrien.email_address,
        offender_name: offender_name,
        offender_no: "G2911GD",
        message: '',
        further_info: {},
        url: "http://localhost:3000/prisons/#{prison_code}/prisoners/#{original_allocation.nomis_offender_id}/allocation"
      ).and_return(double(new_allocation_email: new_allocation_email))

      described_class.send_email(allocation: released_allocation, message: "",
                                 pom_nomis_id: released_allocation.primary_pom_nomis_id)

      expect(deallocation_email).to have_received(:deliver_later).with(no_args)
      expect(new_allocation_email).to have_received(:deliver_later).with(no_args)
    end
  end
end
