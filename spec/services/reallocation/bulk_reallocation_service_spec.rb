# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reallocation::BulkReallocationService do
  subject(:service) do
    described_class.new(
      prison: prison,
      source_pom: source_pom,
      target_pom: target_pom,
      journey: journey,
      current_user: 'spo-user',
      email_context_builder: email_context_builder,
    )
  end

  let(:prison) { create(:prison) }
  let(:offender_no) { 'A1111AA' }

  let(:source_pom) do
    instance_double(StaffMember, staff_id: 10_001, full_name_ordered: 'Old, Pom')
  end

  let(:target_pom) do
    instance_double(StaffMember, staff_id: 10_002, full_name_ordered: 'New, Pom', position: 'PO',
                                 first_name: 'New', last_name: 'Pom')
  end

  let(:journey) do
    BulkReallocationJourney.new(
      source_pom_id: 10_001,
      target_pom_id: 10_002,
      selected_offender_ids: [offender_no],
      override_offender_ids: [],
      overrides: {},
    )
  end

  let(:offender) do
    instance_double(
      MpcOffender,
      offender_no: offender_no,
      tier: 'A',
      rosh_level: 'HIGH',
      recommended_pom_type: 'probation',
      full_name_ordered: 'Zephyr, Alice',
      pom_responsible?: true,
      com_responsible?: false,
      ldu_name: 'Some LDU',
      ldu_email_address: 'ldu@example.com',
      allocated_com_name: 'Smith, John',
      allocated_com_email: 'com@example.com',
      handover_start_date: Date.new(2027, 1, 1),
      responsibility_handover_date: Date.new(2028, 1, 1),
      probation_record: true,
      active_alert_labels: [],
    )
  end

  let(:allocation) do
    create(:allocation_history,
           prison: prison.code,
           nomis_offender_id: offender_no,
           primary_pom_nomis_id: source_pom.staff_id)
  end

  let(:selected_case) do
    double('AllocatedOffender',
           nomis_offender_id: offender_no,
           full_name: 'Zephyr, Alice',
           recommended_pom_type: 'probation')
  end
  let(:persisted_allocation) { instance_double(AllocationHistory, primary_pom_nomis_id: target_pom.staff_id) }
  let(:notifier) { instance_double(Reallocation::BulkReallocationNotifier, call: nil) }

  let(:email_context_builder) do
    instance_double(
      Reallocation::EmailContextBuilder,
      build: {
        offender_name: 'Zephyr, Alice',
        prisoner_number: offender_no,
        pom_role: 'Responsible',
        last_oasys_completed: 'No OASys information',
        handover_start_date: '01 Jan 2027',
        handover_completion_date: '01 Jan 2028',
        com_name: 'John Smith',
        com_email: 'com@example.com',
      },
    )
  end

  let(:refreshed_source_pom) do
    instance_double(StaffMember, primary_allocations_count: 5)
  end

  before do
    stub_feature_flag(:rosh_recommendations, enabled: true)
    allocation # ensure it's created

    allow(OffenderService).to receive(:get_offender).with(offender_no).and_return(offender)
    allow(AllocationService).to receive(:create_or_update).and_return(persisted_allocation)
    allow(StaffMember).to receive(:new).with(prison, source_pom.staff_id, nil).and_return(refreshed_source_pom)
    allow(Reallocation::BulkReallocationNotifier).to receive(:new).with(prison:, source_pom:, target_pom:).and_return(notifier)
  end

  describe '#call' do
    it 'calls AllocationService.create_or_update for each selected case' do
      service.call([selected_case], message: 'Moving cases')

      expect(AllocationService).to have_received(:create_or_update).once
    end

    it 'persists allocations before notifying' do
      result = service.call([selected_case], message: 'Moving cases')

      expect(AllocationService).to have_received(:create_or_update) do |_attributes, _further_info, **options|
        expect(options).to include(notify: false)
      end
      expect(notifier).to have_received(:call) { |actual_result| expect(actual_result).to eq(result) }
    end

    it 'passes the correct allocation attributes' do
      service.call([selected_case], message: 'Moving cases')

      expect(AllocationService).to have_received(:create_or_update) do |attributes, further_info, **options|
        expect(attributes).to include(
          primary_pom_nomis_id: 10_002,
          nomis_offender_id: offender_no,
          event: :reallocate_primary_pom,
          event_trigger: :user,
          created_by_username: 'spo-user',
          allocated_at_rosh: 'HIGH',
          prison: prison.code,
          message: 'Moving cases',
        )
        expect(further_info).to include(:last_oasys_completed, :handover_start_date, :handover_completion_date, :com_name, :com_email)
        expect(options).to include(notify: false)
      end
    end

    it 'stores nil override reasons when no override exists for the case' do
      service.call([selected_case], message: 'Moving cases')

      expect(AllocationService).to have_received(:create_or_update) do |attributes, _further_info, **_options|
        expect(attributes[:override_reasons]).to be_nil
      end
    end

    it 'returns a result object suitable for the confirmation step' do
      result = service.call([selected_case], message: 'Moving cases')

      expect(result).to be_a(Reallocation::BulkReallocationResult)
      expect(result.to_confirmation).to include(
        source_pom_id: 10_001,
        target_pom_id: 10_002,
        message: 'Moving cases',
        remaining_cases_count: 5,
      )
      expect(result.to_confirmation[:selected_cases]).to eq([{ full_name: 'Zephyr, Alice', nomis_offender_id: offender_no }])
    end

    it 'returns the allocations summary needed for the bulk email templates' do
      result = service.call([selected_case], message: 'Moving cases')

      expect(result.allocations_for_email).to eq([
        'Zephyr, Alice (A1111AA) – responsible'
      ])
    end

    context 'when the allocation history does not exist (new allocation)' do
      before do
        AllocationHistory.where(nomis_offender_id: offender_no).delete_all
      end

      it 'uses allocate_primary_pom as the event' do
        service.call([selected_case], message: '')

        expect(AllocationService).to have_received(:create_or_update) do |attributes, _further_info, **options|
          expect(attributes).to include(event: :allocate_primary_pom)
          expect(options).to include(notify: false)
        end
      end
    end

    context 'when rosh_recommendations is disabled' do
      before do
        stub_feature_flag(:rosh_recommendations, enabled: false)
      end

      it 'stores nil allocated_at_rosh' do
        service.call([selected_case], message: 'Moving cases')

        expect(AllocationService).to have_received(:create_or_update) do |attributes, _further_info, **_options|
          expect(attributes[:allocated_at_rosh]).to be_nil
        end
      end
    end
  end
end
