# frozen_string_literal: true

module Reallocations
  class JourneyController < BaseController
    before_action :load_pom, :load_new_pom
    before_action :load_reallocation_journey, only: %i[override update_override summary complete]
    before_action :load_override_case, only: %i[override update_override]
    before_action :load_selected_cases, only: %i[summary complete]

    def override
      prepare_override_page(
        OverrideForm.new(@journey.override_for(@override_case.nomis_offender_id))
      )
    end

    def update_override
      if params[:allocate_to_someone_else].present?
        @journey.exclude_offender!(@override_case.nomis_offender_id)
        store_bulk_reallocation_journey!(@journey)

        if @journey.selected_offender_ids.none?
          clear_bulk_reallocation_journey!
          redirect_to prison_reallocation_path and return
        end

        redirect_to next_reallocation_step_path and return
      end

      prepare_override_page(OverrideForm.new(override_params))

      if @override.valid?
        @journey.store_override_attributes!(@override_case.nomis_offender_id, @override.attributes)
        store_bulk_reallocation_journey!(@journey)
        redirect_to next_reallocation_step_path
      else
        render 'reallocations/override', status: :unprocessable_entity
      end
    end

    def summary
      prepare_summary_page(AllocationForm.new)
    end

    def complete
      message = allocation_params.fetch(:message, '').to_s
      prepare_summary_page(AllocationForm.new(message:))

      service = Reallocation::BulkReallocationService.new(
        prison: @prison,
        source_pom: @pom,
        target_pom: @new_pom,
        journey: @journey,
        current_user: current_user,
      )

      result = service.call(@selected_cases, message:)

      store_bulk_reallocation_confirmation!(result)
      clear_bulk_reallocation_journey!

      redirect_to confirmation_prison_reallocation_path(**reallocation_route_params)
    end

    def confirmation
      confirmation = session[BULK_REALLOCATION_CONFIRMATION_SESSION_KEY]&.with_indifferent_access

      unless confirmation.present? &&
        confirmation[:source_pom_id].to_i == @pom.staff_id &&
        confirmation[:target_pom_id].to_i == @new_pom.staff_id
        redirect_to caseload_path, alert: 'Complete a reallocation to view the confirmation page.'
        return
      end

      @message = confirmation[:message]
      @selected_cases = Array(confirmation[:selected_cases]).map(&:with_indifferent_access)
      @remaining_cases_count = confirmation[:remaining_cases_count].to_i
    end

  private

    def caseload_path
      caseload_prison_reallocation_path(**reallocation_route_params)
    end

    def load_reallocation_journey
      @journey = bulk_reallocation_journey

      unless @journey.matches?(@pom.staff_id, @new_pom.staff_id)
        redirect_to caseload_path
        return
      end

      return unless @journey.stale?(primary_allocations_index.keys)

      clear_bulk_reallocation_state!
      redirect_to caseload_path, alert: 'Some cases changed while you were making this reallocation. Choose the cases again.'
    end

    def load_override_case
      @override_case = primary_allocations_index[params.require(:nomis_offender_id)]

      if @override_case.blank?
        redirect_to next_reallocation_step_path
        return
      end

      if @journey.override_offender_ids.include?(@override_case.nomis_offender_id)
        @override_prisoner = OffenderService.get_offender(@override_case.nomis_offender_id)
        return
      end

      redirect_to next_reallocation_step_path
    end

    def load_selected_cases
      @selected_cases = primary_allocations_index.values_at(*@journey.selected_offender_ids).compact

      return if @selected_cases.any?

      clear_bulk_reallocation_state!
      redirect_to caseload_path, alert: 'Choose at least one case to reallocate.'
    end

    def prepare_override_page(form)
      @override = form
      @back_path = previous_override_path || caseload_path
    end

    def prepare_summary_page(form)
      @allocation = form
      @cases_remaining = @pom.primary_allocations_count - @journey.selected_offender_ids.size
      @back_path = summary_back_path
    end

    def previous_override_path
      previous_id = @journey.override_offender_ids
                            .take_while { it != @override_case.nomis_offender_id }
                            .last
      return if previous_id.blank?

      override_prison_reallocation_path(**reallocation_route_params, nomis_offender_id: previous_id)
    end

    def summary_back_path
      previous_id = @journey.override_offender_ids.last
      return caseload_path if previous_id.blank?

      override_prison_reallocation_path(**reallocation_route_params, nomis_offender_id: previous_id)
    end

    def override_params
      params.require(:override_form).permit(
        :more_detail,
        :suitability_detail,
        override_reasons: []
      )
    end

    def allocation_params
      params.require(:allocation_form).permit(:message)
    end
  end
end
