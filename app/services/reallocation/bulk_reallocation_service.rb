# frozen_string_literal: true

module Reallocation
  class BulkReallocationService
    def initialize(prison:, source_pom:, target_pom:, journey:, current_user:,
                   email_context_builder: EmailContextBuilder.new, notifier: BulkReallocationNotifier.new,
                   notify_individually: true)
      @prison = prison
      @source_pom = source_pom
      @target_pom = target_pom
      @journey = journey
      @current_user = current_user
      @email_context_builder = email_context_builder
      @notifier = notifier
      @notify_individually = notify_individually
    end

    # Reallocates every selected (non-excluded) case, then applies the current
    # notification strategy. Returns a result object that can drive the
    # confirmation step and future batch email behaviour
    def call(selected_cases, message:)
      result = BulkReallocationResult.new(
        source_pom_id: source_pom.staff_id,
        target_pom_id: target_pom.staff_id,
        message: message,
        reallocated_cases: selected_cases.map { build_reallocation_result_for(it, message) },
        remaining_cases_count:,
      )

      notifier.call(result) if notify_individually

      result
    end

  private

    attr_reader :prison, :source_pom, :target_pom, :journey, :current_user,
                :email_context_builder, :notifier, :notify_individually

    def build_reallocation_result_for(selected_case, message)
      offender = offender_for(selected_case.nomis_offender_id)
      existing_allocation = AllocationHistory.find_by(prison: prison.code, nomis_offender_id: selected_case.nomis_offender_id)
      override = journey.override_for(selected_case.nomis_offender_id)

      allocation_attributes = {
        primary_pom_nomis_id: target_pom.staff_id,
        nomis_offender_id: selected_case.nomis_offender_id,
        event: allocation_event_for(existing_allocation),
        event_trigger: :user,
        created_by_username: current_user,
        allocated_at_tier: offender.tier,
        recommended_pom_type: recommended_pom_type_for(offender),
        prison: prison.code,
        message: message,
        override_reasons: override[:override_reasons].presence,
        suitability_detail: override[:suitability_detail],
        override_detail: override[:more_detail],
      }

      notification_context = email_context_builder.build(
        offender: offender,
        pom: target_pom,
        prev_pom_name: source_pom.full_name_ordered,
      ).slice(:last_oasys_completed, :handover_start_date, :handover_completion_date, :com_name, :com_email)

      persisted_allocation = AllocationService.create_or_update(allocation_attributes, notification_context, notify: false)

      BulkReallocationResult::ReallocatedCase.new(
        allocation: persisted_allocation,
        selected_case: selected_case,
        further_info: notification_context,
      )
    end

    def allocation_event_for(existing_allocation)
      existing_allocation&.active? ? :reallocate_primary_pom : :allocate_primary_pom
    end

    def recommended_pom_type_for(offender)
      offender.recommended_pom_type == RecommendationService::PRISON_POM ? 'prison' : 'probation'
    end

    def offender_for(nomis_offender_id)
      @offenders_by_id ||= {}
      @offenders_by_id[nomis_offender_id] ||= OffenderService.get_offender(nomis_offender_id)
    end

    def remaining_cases_count
      # source_pom may already have cached allocations from earlier in the request,
      # so we build a fresh StaffMember before reading the post-reallocation count
      StaffMember.new(prison, source_pom.staff_id, nil).primary_allocations_count
    end
  end
end
