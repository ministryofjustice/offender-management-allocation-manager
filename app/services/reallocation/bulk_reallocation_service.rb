# frozen_string_literal: true

module Reallocation
  class BulkReallocationService
    attr_reader :prison, :source_pom, :target_pom, :journey, :current_user, :email_context_builder

    def initialize(prison:, source_pom:, target_pom:, journey:, current_user:,
                   email_context_builder: EmailContextBuilder.new)
      @prison = prison
      @source_pom = source_pom
      @target_pom = target_pom
      @journey = journey
      @current_user = current_user
      @email_context_builder = email_context_builder
    end

    # Reallocates every selected (non-excluded) case, then applies the current
    # notification strategy. Returns a result object that can drive the
    # confirmation step and future batch email behaviour
    def call(selected_cases, message:)
      reallocated_cases, failed_cases = reallocate_each(selected_cases, message)

      if remaining_cases_count.zero?
        if source_pom.in_limbo?
          # Fully remove the POM: deallocates all leftover allocations,
          # soft-deletes the PomDetail, and removes their NOMIS role
          NomisUserRolesService.remove_pom(prison, source_pom.staff_id)
        else
          # Deallocate leftover allocations but keep the POM in the service
          AllocationHistory.deallocate_pom(
            source_pom.staff_id, prison.code, event_trigger: AllocationHistory::INACTIVE_POM
          )
        end
      end

      build_result(message, reallocated_cases, failed_cases).tap do |result|
        BulkReallocationNotifier.new(prison:, source_pom:, target_pom:).call(result)
      end
    end

  private

    def reallocate_each(selected_cases, message)
      reallocated_cases = []
      failed_cases = []

      selected_cases.each do |selected_case|
        reallocated_cases << build_reallocation_result_for(selected_case, message)
      rescue StandardError => e
        Rails.logger.error(
          "event=bulk_reallocation_case_failed,nomis_offender_id=#{selected_case.nomis_offender_id}|#{e.message}"
        )
        failed_cases << BulkReallocationResult::FailedCase.new(selected_case:, error: e)
      end

      [reallocated_cases, failed_cases]
    end

    def build_result(message, reallocated_cases, failed_cases)
      BulkReallocationResult.new(
        source_pom_id: source_pom.staff_id,
        target_pom_id: target_pom.staff_id,
        message:,
        reallocated_cases:,
        failed_cases:,
        remaining_cases_count:,
      )
    end

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
        allocated_at_rosh: FeatureFlags.rosh_recommendations.enabled? ? offender.rosh_level : nil,
        recommended_pom_type: recommended_pom_type_for(offender),
        prison: prison.code,
        message: message,
        override_reasons: override[:override_reasons].presence,
        suitability_detail: override[:suitability_detail],
        override_detail: override[:more_detail],
      }

      email_context = email_context_builder.build(
        offender: offender,
        pom: target_pom,
        prev_pom_name: source_pom.full_name_ordered,
      )

      notification_context = email_context.slice(
        :last_oasys_completed, :handover_start_date, :handover_completion_date, :com_name, :com_email
      )

      persisted_allocation = AllocationService.create_or_update(allocation_attributes, notification_context, notify: false)

      BulkReallocationResult::ReallocatedCase.new(
        allocation: persisted_allocation,
        selected_case: selected_case,
        further_info: notification_context,
        email_context: email_context,
      )
    end

    def allocation_event_for(existing_allocation)
      existing_allocation&.active? ? :reallocate_primary_pom : :allocate_primary_pom
    end

    def recommended_pom_type_for(offender)
      RecommendationService::POM_TYPE_LABELS.fetch(offender.recommended_pom_type)
    end

    def offender_for(nomis_offender_id)
      @offenders_by_id ||= {}
      @offenders_by_id[nomis_offender_id] ||= OffenderService.get_offender(
        nomis_offender_id, fetch_categories: false, fetch_movements: false
      )
    end

    def remaining_cases_count
      AllocationHistory.active.for_primary_pom(source_pom.staff_id).at_prison(prison)
        .where(nomis_offender_id: prison.all_policy_offenders.map(&:offender_no)).count
    end
  end
end
